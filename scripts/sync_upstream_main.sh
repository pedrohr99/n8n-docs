#!/usr/bin/env bash

# Sync selected branches with <upstream>/main and push to <origin>
#
# Default branches: main develop feature/pdf feature/templates
# Default remotes:  upstream (source) and origin (your fork)
# Default mode:     merge (use --rebase to rebase instead)
#
# Usage:
#   scripts/sync_upstream_main.sh [options] [branch1 branch2 ...]
#
# Options:
#   -b, --branches "b1 b2"   Space- or comma-separated list of branches to sync
#   --upstream <name>         Remote name for upstream (default: upstream)
#   --origin <name>           Remote name for origin (default: origin)
#   --merge                   Use merge strategy (default)
#   --rebase                  Use rebase strategy instead of merge
#   --no-push                 Do not push to origin after updating
#   --abort-on-conflict       Abort merge/rebase on conflicts (leave branch unchanged)
#   --stash                   Temporarily stash local changes before switching branches and restore after
#   -v, --verbose             Verbose output
#   -h, --help                Show help
#
# Examples:
#   scripts/sync_upstream_main.sh                          # sync defaults
#   scripts/sync_upstream_main.sh --rebase --no-push       # rebase, do not push
#   scripts/sync_upstream_main.sh -b "main develop"        # only main and develop
#   scripts/sync_upstream_main.sh feature/pdf              # provide branches directly

set -o pipefail

UPSTREAM_REMOTE="upstream"
ORIGIN_REMOTE="origin"
MODE="merge"          # or "rebase"
DO_PUSH=1
VERBOSE=0
ABORT_ON_CONFLICT=0
USE_STASH=0

# Defaults; can be overridden by args
BRANCHES=(main develop feature/pdf feature/templates)

log_info()  { echo "[sync] $*"; }
log_warn()  { echo "[sync][warn] $*" >&2; }
log_error() { echo "[sync][error] $*" >&2; }

usage() {
  sed -n '1,80p' "$0" | sed -n '/^# Usage:/,$p' | sed 's/^# \{0,1\}//'
}

is_git_repo() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1
}

branch_exists_local() {
  git show-ref --verify --quiet "refs/heads/$1"
}

branch_exists_remote() {
  local remote="$1"; local branch="$2"
  git ls-remote --exit-code --heads "$remote" "$branch" >/dev/null 2>&1
}

remote_exists() {
  git remote get-url "$1" >/dev/null 2>&1
}

run() {
  if [[ $VERBOSE -eq 1 ]]; then
    echo "+ $*"
  fi
  "$@"
}

parse_branches_arg() {
  # Accept space or comma separated list in one string
  local list="$1"
  # Replace commas with spaces, squeeze spaces
  list=$(echo "$list" | tr ',' ' ')
  # shellcheck disable=SC2206
  BRANCHES=($list)
}

EXTRA_BRANCHES=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    -b|--branches)
      shift
      [[ -z "$1" ]] && { log_error "--branches requires a value"; exit 1; }
      parse_branches_arg "$1"
      ;;
    --upstream)
      shift; UPSTREAM_REMOTE="${1:?--upstream requires a value}" ;;
    --origin)
      shift; ORIGIN_REMOTE="${1:?--origin requires a value}" ;;
    --merge)
      MODE="merge" ;;
    --rebase)
      MODE="rebase" ;;
    --no-push)
      DO_PUSH=0 ;;
    --abort-on-conflict)
      ABORT_ON_CONFLICT=1 ;;
    --stash)
      USE_STASH=1 ;;
    -v|--verbose)
      VERBOSE=1 ;;
    -h|--help)
      usage; exit 0 ;;
    --)
      shift; EXTRA_BRANCHES+=("$@"); break ;;
    -*)
      log_error "Unknown option: $1"; usage; exit 1 ;;
    *)
      EXTRA_BRANCHES+=("$1") ;;
  esac
  shift || true
done

if [[ ${#EXTRA_BRANCHES[@]} -gt 0 ]]; then
  BRANCHES=("${EXTRA_BRANCHES[@]}")
fi

if ! is_git_repo; then
  log_error "This script must be run inside a git repository."; exit 1
fi

if ! remote_exists "$UPSTREAM_REMOTE"; then
  log_error "Remote '$UPSTREAM_REMOTE' not found. Use --upstream to specify."; exit 1
fi
if ! remote_exists "$ORIGIN_REMOTE"; then
  log_error "Remote '$ORIGIN_REMOTE' not found. Use --origin to specify."; exit 1
fi

# Remember starting branch
START_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")

# Optionally stash local changes once, to avoid blocking checkout
CLEAN_WORKTREE=1
git diff-index --quiet HEAD -- || CLEAN_WORKTREE=0
STASH_NAME="sync_upstream_main_$(date +%s)"
STASH_MADE=0
if [[ $USE_STASH -eq 1 && $CLEAN_WORKTREE -eq 0 ]]; then
  log_info "Stashing local changes before syncing (name: $STASH_NAME)"
  run git stash push -u -m "$STASH_NAME" || {
    log_error "Failed to stash changes."; exit 1; }
  STASH_MADE=1
fi

log_info "Fetching latest from '$UPSTREAM_REMOTE' and '$ORIGIN_REMOTE'..."
run git fetch --prune "$UPSTREAM_REMOTE" || { log_error "Fetch from $UPSTREAM_REMOTE failed"; exit 1; }
run git fetch --prune "$ORIGIN_REMOTE"   || { log_error "Fetch from $ORIGIN_REMOTE failed"; exit 1; }

log_info "Mode: $MODE | Push: $([[ $DO_PUSH -eq 1 ]] && echo yes || echo no) | Upstream: $UPSTREAM_REMOTE | Origin: $ORIGIN_REMOTE"
log_info "Branches to sync: ${BRANCHES[*]}"

update_branch() {
  local branch="$1"
  log_info "\n=== Syncing branch '$branch' ==="

  # Ensure branch exists locally; if not, create from origin if available
  if ! branch_exists_local "$branch"; then
    if branch_exists_remote "$ORIGIN_REMOTE" "$branch"; then
      log_info "Creating local branch '$branch' from $ORIGIN_REMOTE/$branch"
      run git checkout -B "$branch" "$ORIGIN_REMOTE/$branch" || {
        log_error "Failed to create local branch '$branch'"; return 1; }
    else
      log_warn "Branch '$branch' does not exist locally or on $ORIGIN_REMOTE. Skipping."
      return 0
    fi
  else
    run git checkout "$branch" || { log_error "Failed to checkout '$branch'"; return 1; }
  fi

  # Merge/rebase
  if [[ "$MODE" == "merge" ]]; then
    log_info "Merging $UPSTREAM_REMOTE/main into $branch"
    if ! run git merge --no-edit "$UPSTREAM_REMOTE/main"; then
      log_warn "Merge encountered issues on '$branch'"
      if [[ $ABORT_ON_CONFLICT -eq 1 ]]; then
        log_info "Aborting merge due to --abort-on-conflict"
        git merge --abort >/dev/null 2>&1 || true
      fi
      return 1
    fi
  else
    log_info "Rebasing $branch onto $UPSTREAM_REMOTE/main"
    if ! run git rebase "$UPSTREAM_REMOTE/main"; then
      log_warn "Rebase encountered issues on '$branch'"
      if [[ $ABORT_ON_CONFLICT -eq 1 ]]; then
        log_info "Aborting rebase due to --abort-on-conflict"
        git rebase --abort >/dev/null 2>&1 || true
      fi
      return 1
    fi
  fi

  if [[ $DO_PUSH -eq 1 ]]; then
    log_info "Pushing '$branch' to $ORIGIN_REMOTE/$branch"
    run git push "$ORIGIN_REMOTE" "$branch" || { log_error "Push failed for '$branch'"; return 1; }
  fi

  return 0
}

FAILURES=()
for b in "${BRANCHES[@]}"; do
  if ! update_branch "$b"; then
    FAILURES+=("$b")
  fi
done

# Return to starting branch and restore stash (if any)
if [[ -n "$START_BRANCH" ]]; then
  run git checkout "$START_BRANCH" >/dev/null 2>&1 || true
fi
if [[ $STASH_MADE -eq 1 ]]; then
  log_info "Restoring stashed changes (may cause conflicts)"
  git stash list | grep -q "$STASH_NAME" && run git stash pop || true
fi

if [[ ${#FAILURES[@]} -gt 0 ]]; then
  log_warn "Completed with issues in branches: ${FAILURES[*]}"
  if [[ $ABORT_ON_CONFLICT -eq 0 ]]; then
    log_warn "Tip: rerun with --abort-on-conflict to auto-abort problematic merges/rebases."
  fi
  exit 2
fi

log_info "All requested branches are up to date with $UPSTREAM_REMOTE/main."
exit 0
