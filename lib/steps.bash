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

      readarray -d ';' -t step_vars <<< "$selection"

      # for each selected environment, write the template with the required variable names
      (
        # the first item is always called environment
        if [[ ${#step_vars[@]} -gt 0 ]]; then
          export STEP_ENVIRONMENT="${step_vars[0]}"
          echo "STEP_ENVIRONMENT=${step_vars[0]}"
        fi

        # output > 1 as named in step-var-names, making up a default if needed
        for ((i=1; i < ${#step_vars[@]}; ++i)); do
          nm_idx=$i-1
          var_name="step_var_${i}"
          if [[ ${#var_names[@]} -gt $nm_idx ]]; then
            var_name="${var_names[$nm_idx]}"
          fi

          echo "${var_name^^}=${step_vars[$i]}"
          export "${var_name^^}"="${step_vars[$i]}"
        done

        # does the env file exist? then load it. this will need to be more robust probably
        #export $(grep -v '^#' ".buildkite/deploy/${env_name}.env" | xargs)

        # buildkite-agent pipeline upload .buildkite/deploy-steps.yml
        echo "write ${template} with env"
      )
    done <<< "$selected_environments"
  fi
}
