#!/usr/bin/env bats

set -eou pipefail

load '/usr/local/lib/bats/load.bash'
load '../lib/steps'

# Uncomment the following line to debug stub failures
# export BUILDKITE_AGENT_STUB_DEBUG=/dev/tty

@test "env_filename_for_environment works for relative file" {
  file="$(env_filename_for_environment ".buildkite/template.yaml" "flamingo")"

  assert_equal "${file}" ".buildkite/flamingo.env"
}

@test "env_filename_for_environment works for simple file" {
  file="$(env_filename_for_environment "template.yaml" "flamingo")"

  assert_equal "${file}" "./flamingo.env"
}

@test "load_env_file loads into environment" {
    load_env_file "./tests/fixtures/env/basic.env"

    assert_equal "${one}" "first"
    assert_equal "${two}" "second"
    assert_equal "${three}" "third"
}

@test "load_env_file loads file with spaces in values into environment" {
    load_env_file "./tests/fixtures/env/spaces.env"

    assert_equal "${onespace}" "first one"
    assert_equal "${twospace}" "second two"
    assert_equal "${threespace}" "third three"
}
