#!/usr/bin/env bats

load "$BATS_PLUGIN_PATH/load.bash"
load '../lib/shared'

# Uncomment the following line to debug stub failures
# export BUILDKITE_AGENT_STUB_DEBUG=/dev/tty

setup() {
  export BUILDKITE_PIPELINE_DEFAULT_BRANCH="default-value-from-setup"
  TEMPLATE_DIR=$(mktemp -d)
}

teardown() {
  rm -rf $TEMPLATE_DIR
}

function create_template_file() {
  local path="$1"
  local content="$2"
  mkdir -p "$(dirname "${path}")"
  echo "${content}" >"${path}"
}

@test "extract_key_from_template extracts key from valid template" {
  create_template_file "$TEMPLATE_DIR/valid_template.yaml" "key: example-key"
  key="$(extract_key_from_template "$TEMPLATE_DIR/valid_template.yaml")"

  assert_equal "${key}" "example-key"
}

@test "extract_key_from_template returns empty string for template without key" {
  create_template_file "$TEMPLATE_DIR/no_key_template.yaml" "name: example-name"
  key="$(extract_key_from_template "$TEMPLATE_DIR/no_key_template.yaml")"

  assert_equal "${key}" ""
}

@test "extract_key_from_template handles missing file gracefully" {
  key="$(extract_key_from_template "$TEMPLATE_DIR/missing_template.yaml")"

  assert_equal "${key}" ""
}

@test "extract_key_from_template extracts the first key when multiple keys have the same value" {
  create_template_file "$TEMPLATE_DIR/same_keys_template.yaml" "key: example-key\nkey: example-key"
  key="$(extract_key_from_template "$TEMPLATE_DIR/same_keys_template.yaml")"

  assert_equal "${key}" "example-key"
}

@test "extract_key_from_template extracts the first key when multiple keys have different values" {
  create_template_file "$TEMPLATE_DIR/different_keys_template.yaml" "key: first-key\nkey: second-key"
  key="$(extract_key_from_template "$TEMPLATE_DIR/different_keys_template.yaml")"

  assert_equal "${key}" "first-key"
}

@test "validate_branch_up_to_date succeeds when branch is up-to-date" {
  stub git \
    "fetch origin main : exit 0" \
    "merge-base --is-ancestor HEAD origin/main : exit 0"

  run validate_branch_up_to_date "main"

  assert_success
  assert_output --partial "✅ Current commit includes all changes from origin/main"
  unstub git
}

@test "validate_branch_up_to_date fails when branch is behind" {
  stub git \
    "fetch origin main : exit 0" \
    "merge-base --is-ancestor HEAD origin/main : exit 1"

  run validate_branch_up_to_date "main"

  assert_failure
  assert_output --partial "❌ Current commit is missing changes from origin/main"
  assert_output --partial "Run 'git pull origin main' to update your branch"
  unstub git
}

@test "validate_branch_up_to_date fails when fetch fails" {
  stub git \
    "fetch origin main : exit 1"

  run validate_branch_up_to_date "main"

  assert_failure
  assert_output --partial "❌ Failed to fetch from origin/main"
  assert_output --partial "Make sure the branch 'main' exists on origin"
  unstub git
}

@test "validate_branch_up_to_date uses default branch when none specified" {
  stub git \
    "fetch origin main : exit 0" \
    "merge-base --is-ancestor HEAD origin/main : exit 0"

  run validate_branch_up_to_date

  assert_success
  assert_output --partial "✅ Current commit includes all changes from origin/main"
  unstub git
}

@test "validate_branch_up_to_date works with custom branch" {
  stub git \
    "fetch origin develop : exit 0" \
    "merge-base --is-ancestor HEAD origin/develop : exit 0"

  run validate_branch_up_to_date "develop"

  assert_success
  assert_output --partial "✅ Current commit includes all changes from origin/develop"
  unstub git
}

@test "validate_branch_up_to_date with must-be-branch-head succeeds when both checks pass" {
  stub git \
    "fetch origin main : exit 0" \
    "merge-base --is-ancestor HEAD origin/main : exit 0" \
    "branch --show-current : echo feature-branch" \
    "fetch origin feature-branch : exit 0" \
    "diff --quiet HEAD origin/feature-branch : exit 0"

  run validate_branch_up_to_date "main" "true"

  assert_success
  assert_output --partial "✅ Current commit includes all changes from origin/main"
  assert_output --partial "✅ Current commit is the latest on origin/feature-branch"
  unstub git
}

@test "validate_branch_up_to_date with must-be-branch-head fails when current branch is behind" {
  stub git \
    "fetch origin main : exit 0" \
    "merge-base --is-ancestor HEAD origin/main : exit 0" \
    "branch --show-current : echo feature-branch" \
    "fetch origin feature-branch : exit 0" \
    "diff --quiet HEAD origin/feature-branch : exit 1"

  run validate_branch_up_to_date "main" "true"

  assert_failure
  assert_output --partial "✅ Current commit includes all changes from origin/main"
  assert_output --partial "❌ Current commit is not the latest on origin/feature-branch"
  assert_output --partial "Run 'git pull origin feature-branch' to get the latest commits"
  unstub git
}

@test "validate_branch_up_to_date with must-be-branch-head handles detached HEAD" {
  stub git \
    "fetch origin main : exit 0" \
    "merge-base --is-ancestor HEAD origin/main : exit 0" \
    "branch --show-current : echo"

  run validate_branch_up_to_date "main" "true"

  assert_failure
  assert_output --partial "✅ Current commit includes all changes from origin/main"
  assert_output --partial "❌ Unable to determine current branch (detached HEAD?)"
  assert_output --partial "Make sure you're on a named branch, not a detached HEAD"
  unstub git
}

@test "validate_branch_up_to_date with must-be-branch-head handles missing remote branch" {
  stub git \
    "fetch origin main : exit 0" \
    "merge-base --is-ancestor HEAD origin/main : exit 0" \
    "branch --show-current : echo feature-branch" \
    "fetch origin feature-branch : exit 1"

  run validate_branch_up_to_date "main" "true"

  assert_success
  assert_output --partial "✅ Current commit includes all changes from origin/main"
  assert_output --partial "⚠️ Unable to fetch origin/feature-branch (branch may not exist on remote)"
  assert_output --partial "Skipping current branch head check"
  unstub git
}

@test "validate_branch_up_to_date with must-be-branch-head skips check when on upstream branch" {
  stub git \
    "fetch origin main : exit 0" \
    "merge-base --is-ancestor HEAD origin/main : exit 0" \
    "branch --show-current : echo main"

  run validate_branch_up_to_date "main" "true"

  assert_success
  assert_output --partial "✅ Current commit includes all changes from origin/main"
  assert_output --partial "--- Skipping branch head check (already validated main is up-to-date)"
  unstub git
}
