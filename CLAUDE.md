# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Buildkite plugin that allows steps to be injected into pipelines based on common templates. It enables dynamic pipeline generation where environments can be selected via UI block steps or automatically configured, with the plugin rendering step templates for each selected environment.

## Development Commands

### Testing
```bash
# Run all tests using BATS testing framework
docker-compose run --rm tests

# Run specific test files
docker-compose run --rm tests bats tests/command.bats
docker-compose run --rm tests bats tests/shared.bats
docker-compose run --rm tests bats tests/steps_util.bats
docker-compose run --rm tests bats tests/steps_write.bats
```

### Linting
```bash
# Run plugin linter
docker-compose run --rm lint
```

## Architecture

### Core Components

- **hooks/command**: Main entry point that orchestrates the plugin execution
- **lib/shared.bash**: Shared utilities for plugin configuration reading and key extraction
- **lib/steps.bash**: Core logic for rendering step templates with environment variables

### Plugin Flow

1. **Configuration Reading**: Plugin reads configuration from environment variables prefixed with `BUILDKITE_PLUGIN_STEP_TEMPLATES_`
2. **Template Validation**: Ensures step-template exists and either selector-template or auto-selections are provided
3. **Key Extraction**: Extracts metadata key from selector template using regex pattern matching
4. **Environment Processing**:
   - Reads selected environments from Buildkite metadata
   - Processes auto-selections if provided
   - Sets up environment variables (STEP_ENVIRONMENT, STEP_SELECTOR_ID, named variables)
5. **Template Rendering**: Uploads pipeline fragments using `buildkite-agent pipeline upload`

### Environment Variable Handling

- First semicolon-separated value becomes `STEP_ENVIRONMENT`
- Subsequent values become either named variables (from `step-var-names`) or `STEP_VAR_n`
- Optional `.env` files are loaded per environment using the pattern `{environment}.env`
- Supports both simple key=value and export syntax in env files

### Key Features

- **Dynamic Environment Selection**: UI-driven environment selection via block steps
- **Auto-selections**: Predefined environments that render automatically
- **Template Parameterization**: Environment-specific variable substitution
- **Environment Files**: Per-environment configuration loading
- **Branch Filtering**: Auto-selections support different branch filtering via `AUTO_SELECTION_DEFAULT_BRANCH`

## Testing Strategy

Uses BATS (Bash Automated Testing System) with comprehensive test coverage:
- `command.bats`: Tests main plugin execution flow
- `shared.bats`: Tests utility functions
- `steps_util.bats`: Tests step processing utilities
- `steps_write.bats`: Tests step template rendering

Test fixtures are organized in `tests/fixtures/` with sample configurations and mock binaries.

## MCP Rules

- When using Context7 maintain a file named library.md to store a Library IDs that you search for and before searching make sure that you check the file and use the library ID already available. Otherwise search for it.
