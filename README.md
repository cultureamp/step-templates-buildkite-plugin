# Step Templates Buildkite Plugin

Allows steps to be injected into the pipeline based on a common template.

## Example

Add the following to your `pipeline.yml`:

```yml
steps:
  - command: ls
    plugins:
      - cultureamp/step-templates#v1.0.0:
          step-template: deploy-steps.yml
          step-var-names: ["account", "env", "region"]
          auto-selections:
            - "production-us;production;us-west-1"
            - "production-eu;production;eu-west-2"
          selector-template: deploy-selector.yml
```

## Configuration

### `template` (Required, string)

[TBD]

### `auto-selections` (Optional, string)

[TBD]

### `selector` (Optional, string)

[TBD]

## Developing

To run the tests:

```shell
docker-compose run --rm tests
```
