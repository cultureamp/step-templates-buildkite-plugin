#!/usr/bin/env bats

load '/usr/local/lib/bats/load.bash'

# Uncomment the following line to debug stub failures
# export BUILDKITE_AGENT_STUB_DEBUG=/dev/tty

@test "Creates an annotation with the file count" {
  export BUILDKITE_PLUGIN_FILE_COUNTER_PATTERN="*.bats"

  stub buildkite-agent 'annotate "Found 1 files matching *.bats" : echo Annotation created'

  run "$PWD/hooks/post-command"

  assert_success
  assert_output --partial "Found 1 files matching *.bats"
  assert_output --partial "Annotation created"

  unstub buildkite-agent
}