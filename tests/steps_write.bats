#!/usr/bin/env bats

set -eou pipefail

load '/usr/local/lib/bats/load.bash'
load '../lib/steps'

# Uncomment the following line to debug stub failures
export BUILDKITE_AGENT_STUB_DEBUG=/dev/tty

setup() {
  export unstub_path="$PATH"
  export PATH="$BATS_TEST_DIRNAME/fixtures/bin:$PATH"

  mkdir /tmp/steps 2>&1 | true
  cat > /tmp/steps/c.env <<<'
file_arg=loaded
'
}

teardown() {
  export PATH="$unstub_path"
  [ -d "/tmp/steps" ] && rm -rf /tmp/steps
}

@test "write_steps runs template for each env" {
  local template="/tmp/steps/template.yaml"

  run write_steps "$template" "" $'a\nb\nc'
  assert_success

  assert_output --partial "stubargs(a):pipeline upload /tmp/steps/template.yaml"
  assert_output --partial "stubargs(b):pipeline upload /tmp/steps/template.yaml"
  assert_output --partial "stubargs(c):pipeline upload /tmp/steps/template.yaml"
}

@test "write_steps creates arguments with default names for each env" {
  local template="/tmp/steps/template.yaml"

  run write_steps "$template" "" $'a;aa\nb\nc;c1;c2;c3'
  assert_success

  assert_output --partial "stubenv(a): STEP_VAR_1=aa"
  assert_output --partial "stubenv(c): STEP_VAR_1=c1"
  assert_output --partial "stubenv(c): STEP_VAR_2=c2"
  assert_output --partial "stubenv(c): STEP_VAR_3=c3"
  refute_output --partial "stubenv(c): STEP_VAR_4"
}

@test "write_steps creates arguments with specified names" {
  local template="/tmp/steps/template.yaml"

  run write_steps "$template" $'named_1\nnamed_2' $'a;aa\nb\nc;c1;c2;c3'
  assert_success

  # named vars should exist where names supplied
  assert_output --partial "stubnamed(a): NAMED_1=aa"
  assert_output --partial "stubnamed(c): NAMED_1=c1"
  assert_output --partial "stubnamed(c): NAMED_2=c2"
  assert_output --partial "stubenv(c): STEP_VAR_3=c3"

  # no unexpected args
  refute_output --partial "stubnamed(c): STEP_VAR_4"

  # default vars should not be present
  refute_output --partial "stubenv(a): STEP_VAR_1=aa"
  refute_output --partial "stubenv(c): STEP_VAR_1=c1"
  refute_output --partial "stubenv(c): STEP_VAR_2=c2"
}
