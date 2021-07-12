# Step Templates Buildkite Plugin

Allows steps to be injected into the pipeline based on a common template.

## Background

A common requirement at Culture Amp is to have a series of steps that are repeated
(either on demand or automatically) by environment. This is done by writing a block/select
step, after which a generation script is run. The script then uploads pipeline steps
for each of the selected environments.

For example, if there were two destination environments: "development" and "production",
and a step ran a bash script to execute for each, you would have a selection step with
a pipeline step:

```yaml
  - block: Deploy to?
    fields:
      - select: Environment
        key: deploy-environment
        multiple: true
        required: true
        options:
          - label: Dev
            value: development
          - label: Prod
            value: production

  - name: ":pipeline:"
    command: "bin/ci_deployment_steps"
```

The deployment steps script gets the `deploy-environment` key from build metadata,
then runs `buildkite-agent pipeline upload` on a YAML fragment:

```yaml
steps:
  - label: "Deploy to ${STEP_ENVIRONMENT})"
    depends_on: "build"
    command: "bin/ci_deploy"
    env:
      TARGET: ${STEP_ENVIRONMENT}
    concurrency: 1
    concurrency_group: ${BUILDKITE_PIPELINE_SLUG}/${STEP_ENVIRONMENT}/deploy
    agents:
      queue: ${AGENT}
```

The environment changes for each `upload`, allowing Buildkite to execute differently
in each of the target environments.

A deployment can be made repeatable for a pipeline by uploading the "selection" fragment
after the deployment steps, allowing you to select again.

## Plugin features

This plugin focuses on implementing the script that can output the selection steps and
the deployment steps, reducing the amount of "glue" code that is shared between repositories.

The idea is that the repo supplies at least two ingredients:

1. The environment steps template (`step-template`), and
1. Either (or both) of:
    1. The environment selection template (`selector-template`)
    1. The automatic selections (`auto-selections`)

Given these, the plugin will upload the `step-template` as a pipeline fragment, modifying
the environment for the fragment each time it's uploaded, allowing the same fragment to
be used with different base parameters.

You may optionally supply a series of `.env` files alongside the `step-template`, named
for each of the expected environments. These are key/value pairs that will form part of
the steps environment on each execution.

## Example

Given the following in the `pipeline.yml`:

```yaml
steps:
  - plugins:
      - cultureamp/step-templates#v1.0.0:
          step-template: deploy-steps.yml
          step-var-names: ["type", "region"]
          auto-selections:
            - "production-us;production;us-west-1"
            - "production-eu;production;eu-west-2"
          selector-template: deploy-selector.yml
```

This then will require two other templates to exist, both of which are Buildkite pipelines:

**`deploy-steps.yaml`**

```yaml
# output for each selected environment
steps:
  - label: "Deploy to ${STEP_ENVIRONMENT} (${REGION})"
    depends_on: "build"
    command: "bin/ci_deploy"
    env:
      ENV: ${STEP_ENVIRONMENT}
    concurrency: 1
    concurrency_group: ${BUILDKITE_PIPELINE_SLUG}/${STEP_ENVIRONMENT}/${TYPE}/${REGION}/deploy
    agents:
      queue: ${AGENT}

```

**`deploy-selector.yaml`**

```yaml
# Presents an environment selector driving the output of pipeline
# steps per selected environment

steps:
  - block: Deploy to?
    fields:
      - select: Farm
        key: deploy-environment
        multiple: true
        required: true
        options:
          - label: Env 1
            # semi-colon separated, supplied to the template as environment variables. The first will
            # be called `STEP_ENVIRONMENT`, the second `ENV` and the third, `REGION`
            value: staging-us;preprod;us-west-2
          - label: Env 2
            value: staging-eu;preprod;eu-west-1

  - plugins:
      - cultureamp/step-templates#v1.0.0:
          step-template: deploy-steps.yml
          # names the second and subsequent variables supplied as arguments
          # environment (`ENV` and `REGION`). If this wasn't supplied, they would be called:
          # `STEP_VAR_1` and `STEP_VAR_2`.
          step-var-names: ["type", "region"]
          selector-template: deploy-selector.yml
```

You could (optionally) supply a file called `staging-us.env` alongside `deploy-steps.yml`, with
additional environment variables to set for that environment:

```env
AGENT=staging_agent_pool_name
```

## Configuration

### `step-template` (Required, string)

The template to render for each selected/specified environment. The selected
environment will be presented as `STEP_ENVIRONMENT`, and additional variables
will be given as `STEP_VAR_1` to `STEP_VAR_n` unless named otherwise by
`step-var-names`.

Note that if there a files alongside this YAML file named `STEP_ENVIRONMENT.env`
the key/value pairs specified therein will be present for the template as
environment variables.

### `step-var-names` (Required, string)

The selector can have semi-colon separated values: this names the second
and subsequent values and avoids the default `STEP_VAR_n` name. The supplied
names are uppercased.

Thus if the names were `["type", "region"]`, and the value was
`staging;preprod;us-west-1`, the step template would receive the following
environment:

```env
STEP_ENVIRONMENT=staging
TYPE=preprod
REGION=us-west-1
```

### `auto-selections` (Optional, string)

A list of environment pre-selections that will be rendered immediately by the plugin
using the values specified (semi-colon separated).

When a template is rendered as an auto-selection, the value of the standard
Buildkite variable `BUILDKITE_PIPELINE_DEFAULT_BRANCH` will be copied to an
environment variable named `AUTO_SELECTION_DEFAULT_BRANCH`. This allows steps
rendered for auto-selections to use branch filters that work differently. For
example, a step definition like:

```yaml
steps:
  - label: "Deploy to ${STEP_ENVIRONMENT} (${REGION})"
    command: "bin/ci_deploy"
    branches: "${AUTO_SELECTION_DEFAULT_BRANCH:-*}"
```

When output as an auto-selection, it will only run on the default branch. When
output from a selector, it will run on any branch.

### `selector-template` (Optional, string)

A template containing the available environment specified as a Buildkite pipeline
`block` step that supplies a set of `fields` for selection. The selection may be
optional.

## Developing

To run the tests:

```shell
docker-compose run --rm tests
```

Running the linter:

```shell
docker-compose run --rm lint
```
