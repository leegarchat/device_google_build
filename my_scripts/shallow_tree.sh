#!/bin/bash
# shallow_tree.sh — перевод repo-дерева в shallow (--depth 1) без перезаливки.
#
# Проблема: .repo/project-objects хранит ПОЛНУЮ историю всех проектов (~126G).
# Решение без ре-скачивания всего дерева:
#   1. Фиксирует глубину в конфиге манифеста (repo.depth=1) — то же самое,
#      что делает `repo init --depth=1`. Все будущие `repo sync`
#      (включая вызовы из sync_tree.py) останутся shallow.
#   2. Для каждого проекта: `git fetch --depth=1` (+ докачка HEAD-sha,
#      чтобы checkout остался на месте) — рабочая копия НЕ трогается.
#   3. Для каждого object store: union keep-refs всех расшаренных gitdir'ов,
#      expire reflog, `repack -A -d` + `prune --expire=now`, восстановление
#      guard'а preciousObjects, пересборка commit-graph.
#
# Безопасность:
#   - worktree и индекс не трогаются вообще (только fetch в .git + чистка
#     объектов); локальные изменения пережить конверсию обязаны;
#   - группы с staged-изменениями пропускают фазу gc (только fetch);
#   - shared store'ы чистятся с union всех чужих refs (keep-refs);
#   - guard preciousObjects снимается только на время prune и возвращается
#     обратно с проверкой;
#   - идемпотентно и возобновляемо: повторный запуск пропускает готовое.
#
# sync_tree.py менять НЕ нужно: все его git-операции (show/cat-file/
# checkout HEAD/diff/status/merge-file/repo list/repo sync) shallow-safe,
# а глубину будущих sync держит repo.depth из п.1.
#
# Использование:
#   cd <корень дерева> && ./device/google/build/my_scripts/shallow_tree.sh [-j N] [-y]
#   -j N   параллелизм (default: 8 для fetch, 4 для gc)
#   -y     не спрашивать подтверждение
#
set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JOBS_FETCH=8
JOBS_GC=4
ASSUME_YES=0
STATE_DIR="/tmp/shallow_tree_state"
LOG_FILE="$STATE_DIR/run.log"

usage() { echo "Usage: $0 [-j N] [-y]  (run from Android tree root)"; exit 2; }
while [[ $# -gt 0 ]]; do
    case "$1" in
        -j) JOBS_FETCH="$2"; JOBS_GC="$2"; shift 2 ;;
        -y) ASSUME_YES=1; shift ;;
        -h|--help) usage ;;
        *) echo "Unknown arg: $1"; usage ;;
    esac
done

[[ "$EUID" == "0" ]] && { echo "ERROR: run as tree owner, not root."; exit 1; }
[[ -d ".repo" && -d ".repo/projects" && -d ".repo/project-objects" ]] || {
    echo "ERROR: run from Android tree root (.repo not found)."; exit 1; }
command -v repo >/dev/null && command -v git >/dev/null || {
    echo "ERROR: need 'repo' and 'git' in PATH."; exit 1; }
if pgrep -f "repo (sync|forall)" >/dev/null 2>&1; then
    echo "ERROR: another 'repo sync/forall' seems to be running. Stop it first."
    exit 1
fi

mkdir -p "$STATE_DIR"
exec > >(tee -a "$LOG_FILE") 2>&1

log() { echo "[$(date '+%H:%M:%S')] $*"; }
note() { echo "$1" >> "$STATE_DIR/$2.list"; }

BEFORE_DU=$(du -sh .repo/project-objects 2>/dev/null | cut -f1)
log "project-objects before: $BEFORE_DU | disk free: $(df -h . | tail -1 | awk '{print $4}')"
command -v repo >/dev/null && REPO_N=$(repo list -p 2>/dev/null | wc -l) || REPO_N=0
log "projects in manifest: $REPO_N"

if [[ "$ASSUME_YES" != "1" ]]; then
    echo ""
    echo "Plan: persist repo.depth=1, fetch --depth=1 (~$REPO_N projects),"
    echo "then prune unreachable objects per object store (worktrees untouched)."
    read -r -p "Proceed? [Y/n] " ans
    [[ -z "$ans" || "$ans" =~ ^[YyДд1]$ ]] || { echo "Aborted."; exit 0; }
fi

# ============================================================
# Phase 1 — persist depth (== what `repo init --depth=1` stores)
# ============================================================
log "== Phase 1: persist repo.depth=1 =="
git --git-dir=.repo/manifests.git config repo.depth 1
SAVED=$(git --git-dir=.repo/manifests.git config --get repo.depth || echo "?")
if [[ "$SAVED" != "1" ]]; then log "ERROR: repo.depth not saved (got '$SAVED')"; exit 1; fi
log "repo.depth=1 persisted in .repo/manifests.git/config"

# ============================================================
# Phase 2 — enumerate projects -> gitdir + objects + remotes
# ============================================================
log "== Phase 2: enumerate projects =="
: > "$STATE_DIR/projects.tsv"
: > "$STATE_DIR/no_git.list"
N=0
while IFS= read -r p; do
    [[ -z "$p" ]] && continue
    N=$((N+1))
    GD=$(git -C "$p" rev-parse --absolute-git-dir 2>/dev/null || true)
    if [[ -z "$GD" ]]; then
        # fallback: conventional repo layout
        [[ -d ".repo/projects/$p.git" ]] && GD="$(readlink -f ".repo/projects/$p.git")"
    fi
    if [[ -z "$GD" || ! -d "$GD" ]]; then
        note "$p" "no_git"
        continue
    fi
    OBJ=$(git --git-dir="$GD" rev-parse --git-path objects 2>/dev/null || true)
    [[ -z "$OBJ" ]] && OBJ="$GD/objects"
    OBJR=$(readlink -f "$OBJ" 2>/dev/null || echo "$OBJ")
    REMS=$(git --git-dir="$GD" remote 2>/dev/null | tr '\n' ' ')
    printf '%s\t%s\t%s\t%s\n' "$p" "$GD" "$OBJR" "$REMS" >> "$STATE_DIR/projects.tsv"
done < <(repo list -p 2>/dev/null)
TOTAL=$(wc -l < "$STATE_DIR/projects.tsv")
log "enumerated: $TOTAL with git, $(wc -l < "$STATE_DIR/no_git.list") without git"

export STATE_DIR
fetch_one() {
    line="$1"
    p=$(echo "$line" | cut -f1); gd=$(echo "$line" | cut -f2); rems=$(echo "$line" | cut -f4)
    if grep -qxF "$p" "$STATE_DIR/fetch_done.list" 2>/dev/null; then return 0; fi
    ok=1
    for r in $rems; do
        timeout 600 git --git-dir="$gd" fetch --depth=1 --prune "$r" >/dev/null 2>&1 || ok=0
    done
    # HEAD-sha fetch: puts the checked-out commit on the shallow boundary,
    # so later gc can drop its ancestry without moving the checkout.
    first_remote=$(echo "$rems" | awk '{print $1}')
    if [[ -n "$first_remote" ]]; then
        headsha=$(git --git-dir="$gd" rev-parse HEAD 2>/dev/null || true)
        if [[ -n "$headsha" ]]; then
            timeout 600 git --git-dir="$gd" fetch --depth=1 "$first_remote" "$headsha" >/dev/null 2>&1 || true
        fi
    fi
    if [[ "$ok" == "1" ]]; then echo "$p" >> "$STATE_DIR/fetch_done.list";
    else echo "$p" >> "$STATE_DIR/fetch_failed.list"; fi
}
export -f fetch_one

# ============================================================
# Phase 3 — fetch --depth=1 (parallel, worktree untouched)
# ============================================================
log "== Phase 3: fetch --depth=1 (jobs=$JOBS_FETCH) =="
: >> "$STATE_DIR/fetch_done.list"; : >> "$STATE_DIR/fetch_failed.list"
cut -f1 "$STATE_DIR/projects.tsv" >/dev/null  # warmup
< "$STATE_DIR/projects.tsv" xargs -P "$JOBS_FETCH" -I{} bash -c 'fetch_one "$@"' _ {}
log "fetch done: $(sort -u "$STATE_DIR/fetch_done.list" | wc -l) ok, $(sort -u "$STATE_DIR/fetch_failed.list" 2>/dev/null | wc -l) failed"
# manifest repo itself: fetch shallow too (tiny, keep history out of the way)
git --git-dir=.repo/manifests.git fetch --depth=1 --prune >/dev/null 2>&1 || true
# truncate repo trace log (append-only debug log, safe)
: > .repo/TRACE_FILE 2>/dev/null || true

# ============================================================
# Phase 4 — prune per object store (parallel across stores)
# ============================================================
log "== Phase 4: prune unreachable objects per store (jobs=$JOBS_GC) =="
# group file: objects_realpath \t gitdir (one line per member)
awk -F'\t' '{print $3"\t"$2}' "$STATE_DIR/projects.tsv" | sort -u > "$STATE_DIR/groups.tsv"
cut -f1 "$STATE_DIR/groups.tsv" | sort -u > "$STATE_DIR/stores.list"
log "unique object stores: $(wc -l < "$STATE_DIR/stores.list")"

prune_store() {
    store="$1"
    skey=$(echo -n "$store" | md5sum | cut -d' ' -f1)
    if grep -qxF "$skey" "$STATE_DIR/gc_done.list" 2>/dev/null; then return 0; fi
    members=$(awk -F'\t' -v s="$store" '$1==s{print $2}' "$STATE_DIR/groups.tsv")
    # primary gitdir = first member
    G1=$(echo "$members" | head -1)
    # 1) skip gc if any member has STAGED changes (their blobs live in this store)
    for G in $members; do
        if ! git --git-dir="$G" diff --cached --quiet 2>/dev/null; then
            rc=$?
            if [[ $rc == 1 ]]; then
                echo "$store <- $G" >> "$STATE_DIR/skipped_staged.list"
                return 0
            fi
            # rc>1: git error -> be conservative, skip gc for this store
            echo "$store <- $G (git error)" >> "$STATE_DIR/skipped_staged.list"
            return 0
        fi
    done
    # 2) union keep-refs (protects every member's refs+HEAD in shared stores)
    i=0
    for G in $members; do
        i=$((i+1))
        git --git-dir="$G" for-each-ref --format='%(objectname) %(refname)' 2>/dev/null | \
        while read -r sha ref; do
            git --git-dir="$G1" update-ref "refs/shallow-keep/g$i/${ref#refs/}" "$sha" 2>/dev/null
        done
        H=$(git --git-dir="$G" rev-parse HEAD 2>/dev/null || true)
        [[ -n "$H" ]] && git --git-dir="$G1" update-ref "refs/shallow-keep/g$i/HEAD" "$H" 2>/dev/null
    done
    # 3) expire reflogs everywhere in the group
    for G in $members; do
        git --git-dir="$G" reflog expire --expire=now --all >/dev/null 2>&1 || true
    done
    # 4) temporarily lift preciousObjects guard (repo sets it on shared stores),
    #    then repack-unreachable + prune. Guard restored with verification below.
    had_guard=0
    if [[ "$(git --git-dir="$G1" config --get extensions.preciousObjects 2>/dev/null)" == "true" ]]; then
        had_guard=1
        git --git-dir="$G1" config --unset extensions.preciousObjects
    fi
    git --git-dir="$G1" repack -A -d -l >/dev/null 2>&1
    git --git-dir="$G1" prune --expire=now >/dev/null 2>&1
    # 5) drop keep-refs
    git --git-dir="$G1" for-each-ref --format='%(refname)' refs/shallow-keep 2>/dev/null | \
    while read -r ref; do git --git-dir="$G1" update-ref -d "$ref" 2>/dev/null; done
    # 6) restore guard and VERIFY
    if [[ "$had_guard" == "1" ]]; then
        git --git-dir="$G1" config extensions.preciousObjects true
        [[ "$(git --git-dir="$G1" config --get extensions.preciousObjects 2>/dev/null)" == "true" ]] || {
            echo "$store GUARD-RESTORE-FAILED" >> "$STATE_DIR/errors.list"; return 1; }
    fi
    # 7) rewrite commit-graph if one existed (stale graphs reference pruned commits)
    if [[ -d "$store/info/commit-graphs" || -f "$store/info/commit-graph" ]]; then
        rm -rf "$store/info/commit-graphs" "$store/info/commit-graph"
        git --git-dir="$G1" commit-graph write --reachable >/dev/null 2>&1 || true
    fi
    echo "$skey" >> "$STATE_DIR/gc_done.list"
}
export -f prune_store

: >> "$STATE_DIR/gc_done.list"; : >> "$STATE_DIR/skipped_staged.list"; : >> "$STATE_DIR/errors.list"
< "$STATE_DIR/stores.list" xargs -P "$JOBS_GC" -I{} bash -c 'prune_store "$@"' _ {}
log "gc done: $(sort -u "$STATE_DIR/gc_done.list" | wc -l) stores, skipped-staged: $(wc -l < "$STATE_DIR/skipped_staged.list"), errors: $(wc -l < "$STATE_DIR/errors.list")"
if [[ -s "$STATE_DIR/errors.list" ]]; then log "ERRORS:"; cat "$STATE_DIR/errors.list"; fi

# ============================================================
# Phase 5 — summary
# ============================================================
AFTER_DU=$(du -sh .repo/project-objects 2>/dev/null | cut -f1)
log "project-objects after: $AFTER_DU (was $BEFORE_DU) | disk free: $(df -h . | tail -1 | awk '{print $4}')"
log "no-git projects (repo sync will clone them shallow): $(wc -l < "$STATE_DIR/no_git.list")"
log "fetch-failed (kept full, retry later): $(sort -u "$STATE_DIR/fetch_failed.list" 2>/dev/null | wc -l)"
log "DONE. sync_tree.py works unchanged; future 'repo sync' stays shallow via repo.depth=1."
log "Rollback per project: git fetch --unshallow [<remote>]. Full rollback: unset repo.depth + repo sync."
