#!/usr/bin/env bash
set -Eeuo pipefail

# gh-pr-review-summary.sh
# Summarize GitHub PR reviews and comments using gh + jq.
# Defaults to filtering for CodeRabbit reviews.
#
# Usage:
#   scripts/gh-pr-review-summary.sh [--all | --author <login-regex>] [<pr>]
#
# Examples:
#   scripts/gh-pr-review-summary.sh                    # current branch PR, CodeRabbit only
#   scripts/gh-pr-review-summary.sh 76                 # PR number in current repo
#   scripts/gh-pr-review-summary.sh https://github.com/owner/repo/pull/76
#   scripts/gh-pr-review-summary.sh --all 76           # show all reviewers
#   scripts/gh-pr-review-summary.sh --author "alice|bob" 76

AUTHOR_RE=".*"           # default: show all reviewers
FILTER_ALL=true          # --all is the default behavior
PR_ARG=""

usage() {
  sed -n '1,40p' "$0" | sed 's/^# \{0,1\}//'
}

# Post-filter to strip CodeRabbit's Internal state sections safely
filter_internal_state() {
  awk '
    BEGIN { IGNORECASE=1; in_is=0 }
    {
      # Remove single-line HTML comments that contain "internal state"
      if ($0 ~ /<!--/ && $0 ~ /internal state/ && $0 ~ /-->/) {
        gsub(/<!--[^>]*internal state[^>]*-->/, "");
      }
    }
    # End of an Internal state <details> block
    in_is == 1 && /<\/details>/ { in_is=0; next }
    # Inside an Internal state block: skip
    in_is == 1 { next }
    # Start of an Internal state <details> block
    match($0, /<summary[^>]*>[[:space:]]*internal state[[:space:]]*<\/summary>/) { in_is=1; next }
    # Otherwise print line
    { print }
  '
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage; exit 0 ;;
    --all)
      FILTER_ALL=true; AUTHOR_RE='.*'; shift ;;
    --author)
      [[ $# -ge 2 ]] || { echo "--author requires a regex" >&2; exit 2; }
      AUTHOR_RE="$2"; shift 2 ;;
    --author=*)
      AUTHOR_RE="${1#*=}"; shift ;;
    -a)
      FILTER_ALL=true; shift ;;
    *)
      if [[ -z "$PR_ARG" ]]; then PR_ARG="$1"; else echo "Unexpected arg: $1" >&2; exit 2; fi
      shift ;;
  esac
done

if ! command -v gh >/dev/null 2>&1; then
  echo "Error: gh CLI not found. Install from https://cli.github.com/" >&2
  exit 127
fi
if ! command -v jq >/dev/null 2>&1; then
  echo "Error: jq not found. Install jq to continue." >&2
  exit 127
fi

# Ensure authenticated (prints status if not logged in)
if ! gh auth status -h github.com >/dev/null 2>&1; then
  echo "Error: gh not authenticated. Run: gh auth login" >&2
  exit 1
fi

# Resolve repo and PR number
REPO_NWO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
if [[ -z "${REPO_NWO:-}" ]]; then
  echo "Error: Unable to resolve current repo. Run inside a GitHub repo clone." >&2
  exit 1
fi

PR_NUMBER=$(gh pr view ${PR_ARG:+"$PR_ARG"} --json number -q .number 2>/dev/null || true)
if [[ -z "${PR_NUMBER:-}" ]]; then
  echo "Error: Unable to resolve PR. Provide a PR number or URL, or run on a branch with an open PR." >&2
  exit 1
fi

# Fetch basic PR info
PR_INFO_JSON=$(gh pr view "$PR_NUMBER" --json number,title,author,reviewDecision,url -q '.')

AUTHOR_FILTER_JQ='\(.)'
if [[ "$FILTER_ALL" == true ]]; then AUTHOR_RE='.*'; fi

hr() { printf '%*s\n' "${1:-80}" '' | tr ' ' '-'; }

echo
echo "PR Summary"
hr 80
echo "$PR_INFO_JSON" | jq -r '
  "- URL: " + .url +
  "\n- Number: #" + (.number|tostring) +
  "\n- Title: " + .title +
  "\n- Author: " + .author.login +
  "\n- ReviewDecision: " + (.reviewDecision // "UNKNOWN")
'

echo
echo "Reviews (filter: ${AUTHOR_RE})"
hr 80
# Collect all reviews and flatten pages
REVIEWS_JSON=$(gh api --paginate "repos/$REPO_NWO/pulls/$PR_NUMBER/reviews" 2>/dev/null | jq -s 'add // []')

echo "$REVIEWS_JSON" | jq -r --arg re "$AUTHOR_RE" '
  def strip_internal:
    (. // "")
    | gsub("\r"; "")
  ;
  map(select(.user.login|test($re; "i")))
  | if length==0 then
      "(no matching reviews)"
    else
      sort_by(.submitted_at // "")
      | .[] | (
          "- [" + (.state // "N/A") + "] " + (.submitted_at // "N/A") +
          " by " + .user.login +
          "\n  commit: " + ((.commit_id // "")[0:7]) +
          "\n  body:\n" + ((.body | strip_internal) // "") + "\n"
        )
    end
' | filter_internal_state

echo
echo "Review Comments (filter: ${AUTHOR_RE})"
hr 80
COMMENTS_JSON=$(gh api --paginate "repos/$REPO_NWO/pulls/$PR_NUMBER/comments" 2>/dev/null | jq -s 'add // []')

echo "$COMMENTS_JSON" | jq -r --arg re "$AUTHOR_RE" '
  def strip_internal:
    (. // "")
    | gsub("\r"; "")
  ;
  map(select(.user.login|test($re; "i")))
  | if length==0 then
      "(no matching review comments)"
    else
      sort_by(.path, (.line // .original_line // 0), .id)
      | .[]
      | "- " + (.path // "") + ":" + ((.line // .original_line // 0)|tostring) +
        " (" + .user.login + " @ " + (.updated_at // .created_at // "") + ")\n" +
        (((.body | strip_internal) // "")) + "\n"
    end
' | filter_internal_state

echo
echo "Issue Comments (filter: ${AUTHOR_RE})"
hr 80
ISSUE_COMMENTS_JSON=$(gh api --paginate "repos/$REPO_NWO/issues/$PR_NUMBER/comments" 2>/dev/null | jq -s 'add // []')

echo "$ISSUE_COMMENTS_JSON" | jq -r --arg re "$AUTHOR_RE" '
  def strip_internal:
    (. // "")
    | gsub("\r"; "")
  ;
  map(select(.user.login|test($re; "i")))
  | if length==0 then
      "(no matching issue comments)"
    else
      sort_by(.updated_at // .created_at)
      | .[]
      | "- " + (.user.login) + " @ " + (.updated_at // .created_at // "") +
        "\n" + (((.body | strip_internal) // "")) + "\n"
    end
' | filter_internal_state

echo
echo "Done. Repo: $REPO_NWO, PR: #$PR_NUMBER"
