#!/usr/bin/env bats

load "$BATS_PLUGIN_PATH/load.bash"

# Uncomment the following line to debug stub failures
# export BUILDKITE_AGENT_STUB_DEBUG=/dev/tty

setup() {
  export BUILDKITE_PIPELINE_DEFAULT_BRANCH="default-value-from-setup"
  export BUILDKITE_JOB_ID="7b35feca-d1b9-423a-9cad-4107b6b40dd9"
  export unstub_path="$PATH"
  export PATH="$BATS_TEST_DIRNAME/fixtures/bin:$PATH"
  [ ! -f "/tmp/step-template.yaml" ] && touch /tmp/step-template.yaml
  cat > "/tmp/selector-template.yaml" <<<'
  key: select-key

  key: select-key
  '
}

teardown() {
  export PATH="$unstub_path"
  [ -f "/tmp/step-template.yaml" ] && rm /tmp/step-template.yaml
}

@test "Fails when template not provided" {
  run "$PWD/hooks/command"

  assert_failure
  assert_output --partial "No 'step_template' argument provided"
}

@test "Fails when selector or autos not provided" {
  export BUILDKITE_PLUGIN_STEP_TEMPLATES_STEP_TEMPLATE="step-template.yaml"

  run "$PWD/hooks/command"

  assert_failure
  assert_output --partial "selector-template nor auto-selections specified"
}

@test "Writes steps from auto selections" {
  export BUILDKITE_PLUGIN_STEP_TEMPLATES_STEP_TEMPLATE="/tmp/step-template.yaml"
  export BUILDKITE_PLUGIN_STEP_TEMPLATES_AUTO_SELECTIONS_0="auto-one"
  export BUILDKITE_PLUGIN_STEP_TEMPLATES_AUTO_SELECTIONS_1="auto-two"

  run "$PWD/hooks/command"

  assert_success
  assert_output --partial "stubenv(auto-one): STEP_ENVIRONMENT=auto-one"
  assert_output --partial "stubenv(auto-two): STEP_ENVIRONMENT=auto-two"
}

@test "Writes additional branch variable for auto selections" {
  export BUILDKITE_PLUGIN_STEP_TEMPLATES_STEP_TEMPLATE="/tmp/step-template.yaml"
  export BUILDKITE_PLUGIN_STEP_TEMPLATES_AUTO_SELECTIONS_0="auto-one"
  export BUILDKITE_PLUGIN_STEP_TEMPLATES_AUTO_SELECTIONS_1="auto-two"
  export BUILDKITE_PIPELINE_DEFAULT_BRANCH="default-branch"

  run "$PWD/hooks/command"

  assert_success
  assert_output --partial "stubauto(auto-one): AUTO_SELECTION_DEFAULT_BRANCH=default-branch"
  assert_output --partial "stubauto(auto-two): AUTO_SELECTION_DEFAULT_BRANCH=default-branch"
}

@test "Writes steps from meta-data selections" {
  export BUILDKITE_PLUGIN_STEP_TEMPLATES_STEP_TEMPLATE="/tmp/step-template.yaml"
  export BUILDKITE_PLUGIN_STEP_TEMPLATES_SELECTOR_TEMPLATE="/tmp/selector-template.yaml"

  run "$PWD/hooks/command"

  assert_success
  assert_output --partial "stubenv(select-one): STEP_ENVIRONMENT=select-one"
  assert_output --partial "stubenv(select-two): STEP_ENVIRONMENT=select-two"
}

@test "STEP_SELECTOR_ID is set when BUILDKITE_JOB_ID is provided" {
  export BUILDKITE_PLUGIN_STEP_TEMPLATES_STEP_TEMPLATE="/tmp/step-template.yaml"
  export BUILDKITE_PLUGIN_STEP_TEMPLATES_SELECTOR_TEMPLATE="/tmp/selector-template.yaml"
  export BUILDKITE_JOB_ID="test-job-id"

  run "$PWD/hooks/command"

  assert_success
  assert_output --partial "STEP_SELECTOR_ID=\"test-job-id\""
}

@test "STEP_SELECTOR_ID is empty when BUILDKITE_JOB_ID is not provided" {
  export BUILDKITE_PLUGIN_STEP_TEMPLATES_STEP_TEMPLATE="/tmp/step-template.yaml"
  export BUILDKITE_PLUGIN_STEP_TEMPLATES_SELECTOR_TEMPLATE="/tmp/selector-template.yaml"
  unset BUILDKITE_JOB_ID

  run "$PWD/hooks/command"

  assert_success
  assert_output --partial "STEP_SELECTOR_ID=\"\""
}
