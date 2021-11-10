#!/usr/bin/env bash

# Writes the steps based on a step template

function write_steps() {
  local template="${1}"
  local raw_var_names="${2}"
  local selected_environments="${3}"

  # this is passed as a newline-delimited string, as passing arrays is ... not really a thing
  local var_names; readarray -t var_names <<< "${raw_var_names}"

  if [[ -n "$selected_environments" ]]; then
    while IFS=$'\n' read -r selection;
    do
      if [[ -z $selection ]]; then
        continue
      fi

      IFS=';' read -ra step_vars <<< "$selection"

      # for each selected environment, write the template with the required variable names
      (
        local step_env=""

        msg="--- Writing template \"${template}\""

        # the first item is always called "STEP_ENVIRONMENT"
        if [[ ${#step_vars[@]} -gt 0 ]]; then
          step_env="${step_vars[0]}"
          step_env="$(printf '%s' "$step_env")" # trim trailing space

          msg+=" for environment \"${step_env}\""
        fi
        export STEP_ENVIRONMENT="${step_env}"

        echo "${msg}"
        echo "Environment setup:"
        echo "STEP_ENVIRONMENT=\"${STEP_ENVIRONMENT}\""

        # output > 1 as named in step-var-names, making up a default if needed
        for ((i=1; i < ${#step_vars[@]}; ++i)); do
          val="$(printf '%s' "${step_vars[$i]}")" # trim trailing space

          nm_idx=$i-1
          var_name="step_var_${i}"
          if [[ ${#var_names[@]} -gt $nm_idx && -n "${var_names[$nm_idx]}" ]]; then
            var_name="${var_names[$nm_idx]}"
          fi

          echo "${var_name^^}=\"${val}\""
          export "${var_name^^}"="${val}"
        done

        # find env file based on location of template
        local env_file; env_file="$(env_filename_for_environment "${template}" "${step_env}")"
        if [[ -f "${env_file}" ]]; then
          echo "=> loading ${env_file} into environment..."
          load_env_file "${env_file}"
        else
          echo "=> env file ${env_file} not found, skipping load."
        fi

        buildkite-agent pipeline upload "${template}"
      )
    done <<< "$selected_environments"
  fi
}

function env_filename_for_environment() {
  local template="${1}"
  local step_env="${2}"

  local dir; dir="$(dirname "${template}")"

  echo "${dir}/${step_env}.env"
}

function load_env_file() {
  local env_file="${1}"

  if [[ ! -f "${env_file}" ]]; then
    return
  fi

  if grep -q '^export \w' "${env_file}"; then
    # contains export statements
    source "${env_file}"
  else
    # This only handles simple cases; values with spaces and multiple lines
    # should use the `export` syntax.
    local vars; vars="$(grep -v '^#' "${env_file}")"

    #shellcheck disable=SC2046
    export $(xargs <<< "${vars}")
  fi
}
