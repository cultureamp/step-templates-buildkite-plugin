#!/usr/bin/env bats

load "$BATS_PLUGIN_PATH/load.bash"
load '../lib/shared'

# Uncomment the following line to debug stub failures
# export BUILDKITE_AGENT_STUB_DEBUG=/dev/tty

setup() {
  export BUILDKITE_PIPELINE_DEFAULT_BRANCH="default-value-from-setup"
  TEMPLATE_PATH=/tmp/templates
  mkdir -p $TEMPLATE_PATH
}

teardown() {
  rm -rf $TEMPLATE_PATH
}

function create_template_file() {
  local path="$1"
  local content="$2"
  mkdir -p "$(dirname "${path}")"
  echo "${content}" >"${path}"
}

@test "extract_key_from_template extracts key from valid template" {
  create_template_file "$TEMPLATE_PATH/valid_template.yaml" "key: example-key"
  key="$(extract_key_from_template "$TEMPLATE_PATH/valid_template.yaml")"

  assert_equal "${key}" "example-key"
}

@test "extract_key_from_template returns empty string for template without key" {
  create_template_file "$TEMPLATE_PATH/no_key_template.yaml" "name: example-name"
  key="$(extract_key_from_template "$TEMPLATE_PATH/no_key_template.yaml")"

  assert_equal "${key}" ""
}

@test "extract_key_from_template handles missing file gracefully" {
  key="$(extract_key_from_template "$TEMPLATE_PATH/missing_template.yaml")"

  assert_equal "${key}" ""
}

@test "extract_key_from_template extracts the first key when multiple keys have the same value" {
  create_template_file "$TEMPLATE_PATH/same_keys_template.yaml" "key: example-key\nkey: example-key"
  key="$(extract_key_from_template "$TEMPLATE_PATH/same_keys_template.yaml")"

  assert_equal "${key}" "example-key"
}

@test "extract_key_from_template extracts the first key when multiple keys have different values" {
  create_template_file "$TEMPLATE_PATH/different_keys_template.yaml" "key: first-key\nkey: second-key"
  key="$(extract_key_from_template "$TEMPLATE_PATH/different_keys_template.yaml")"

  assert_equal "${key}" "first-key"
}
