#!/usr/bin/env bash

plugin_prefix="BUILDKITE_PLUGIN_STEP_TEMPLATES_"

# Shorthand for reading env config
function plugin_read_config() {
  local var="${plugin_prefix}${1}"
  local default="${2:-}"
  echo "${!var:-$default}"
}

# Reads either a value or a list from plugin config
function plugin_read_list() {
  prefix_read_list "${plugin_prefix}${1}"
}

# Reads either a value or a list from the given env prefix
function prefix_read_list() {
  local prefix="${1}"
  local parameter="${prefix}_0"

  if [[ -n "${!parameter:-}" ]]; then
    local i=0
    local parameter="${prefix}_${i}"
    while [[ -n "${!parameter:-}" ]]; do
      echo "${!parameter}"
      i=$((i+1))
      parameter="${prefix}_${i}"
    done
  elif [[ -n "${!prefix:-}" ]]; then
    echo "${!prefix}"
  fi
}

# Extract the first occurrence of a "key" field from a YAML template file.
#
# Arguments:
#   $1 - The path to the YAML template file.
#
# Behaviour:
#   - Searches for lines in the file that match the pattern "key: <value>".
#   - Extracts the value of the first "key" field found.
#   - If no "key" field is found, returns an empty string.
#
# Example:
#   Given a file with the content:
#     key: example-key
#     key: another-key
#   Running:
#     extract_key_from_template "template.yaml"
#   Will return:
#     example-key
#
#   If the file does not contain a "key" field or does not exist, it will return an empty string.
function extract_key_from_template() {
  local template="$1"
  grep -P -o "(?<=key: )[\w-]+" "${template}" | head -n1 || true
}

# Validates that the current commit meets freshness requirements
#
# Arguments:
#   $1 - The upstream branch to check against (e.g., "main", "master")
#   $2 - Whether to also check current commit is at branch head (true/false, default: false)
#
# Returns:
#   0 if commit meets all requirements
#   1 if commit is stale or validation fails
function validate_branch_up_to_date() {
  local upstream_branch="${1:-main}"
  local check_current_branch_head="${2:-false}"
  local origin_branch="origin/${upstream_branch}"

  echo "--- Checking if current commit includes all changes from ${origin_branch}"

  # Fetch latest changes from origin
  if ! git fetch origin "${upstream_branch}" 2>/dev/null; then
    echo "❌ Failed to fetch from ${origin_branch}"
    echo "Make sure the branch '${upstream_branch}' exists on origin"
    return 1
  fi

  # Check if current HEAD includes all changes from origin branch
  if git merge-base --is-ancestor HEAD "${origin_branch}"; then
    echo "✅ Current commit includes all changes from ${origin_branch}"
  else
    echo "❌ Current commit is missing changes from ${origin_branch}"
    echo "Run 'git pull origin ${upstream_branch}' to update your branch"
    return 1
  fi

  # If requested, also check that we're at the head of our current branch
  if [[ "${check_current_branch_head}" == "true" ]]; then
    local current_branch
    current_branch=$(git branch --show-current 2>/dev/null)

    if [[ -z "${current_branch}" ]]; then
      echo "❌ Unable to determine current branch (detached HEAD?)"
      echo "Make sure you're on a named branch, not a detached HEAD"
      return 1
    fi

    # Skip branch head check if we're already on the upstream branch
    # (we've already validated it's up-to-date above)
    if [[ "${current_branch}" == "${upstream_branch}" ]]; then
      echo "--- Skipping branch head check (already validated ${current_branch} is up-to-date)"
    else
      echo "--- Checking if current commit is the latest on branch '${current_branch}'"

      # Fetch the current branch from origin
      if ! git fetch origin "${current_branch}" 2>/dev/null; then
        echo "⚠️ Unable to fetch origin/${current_branch} (branch may not exist on remote)"
        echo "Skipping current branch head check"
      else
        local origin_current_branch="origin/${current_branch}"

        # Check if HEAD matches the remote branch head
        if git diff --quiet HEAD "${origin_current_branch}"; then
          echo "✅ Current commit is the latest on ${origin_current_branch}"
        else
          echo "❌ Current commit is not the latest on ${origin_current_branch}"
          echo "Run 'git pull origin ${current_branch}' to get the latest commits"
          return 1
        fi
      fi
    fi
  fi

  return 0
}
