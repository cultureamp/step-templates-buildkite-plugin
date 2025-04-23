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
