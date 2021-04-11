# Step Templates Buildkite Plugin

Allows steps to be injected into the pipeline based on a common template.

## Example

Add the following to your `pipeline.yml`:

```yml
steps:
  - command: ls
    plugins:
      - cultureamp/step-templates#v1.0.0:
          template: deploy-steps.yml
          auto-selections:
            - "production-us;production"
            - "production-eu;production"
          selector: deploy-selector.yml
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
