# Toast-cli Architecture

## Overview

Toast-cli is a Python-based CLI tool that provides various utility commands for AWS and Kubernetes management. The architecture follows a plugin-based design pattern, allowing for easy extension of functionality through the addition of new plugins.

## Package Structure

The project is organized as a Python package with the following structure:

```
toast-cli/
  ├── setup.py            # Package setup script
  ├── setup.cfg           # Package configuration
  ├── pyproject.toml      # Build system requirements
  ├── MANIFEST.in         # Additional files to include in the package
  ├── VERSION             # Version information (current: 3.0.0)
  ├── README.md           # Project documentation
  ├── ARCHITECTURE.md     # Architecture documentation
  ├── LICENSE             # License information
  └── toast/              # Main package
      ├── __init__.py     # Package initialization and CLI entry point
      ├── __main__.py     # Entry point for running as a module
      ├── helpers.py      # Helper functions and custom UI elements
      └── plugins/        # Plugin modules
          ├── __init__.py
          ├── base_plugin.py
          ├── am_plugin.py
          ├── cdw_plugin.py
          ├── ctx_plugin.py
          ├── env_plugin.py
          ├── git_plugin.py
          ├── region_plugin.py
          ├── ssm_plugin.py
          ├── update_plugin.py
          └── utils.py
```

## Components

### Main Application Components

#### Main Entry Point (toast/__init__.py)

The main entry point of the application is responsible for:
- Dynamically discovering and loading plugins from the `toast.plugins` package
- Registering plugin commands with the CLI interface using Click
- Running the CLI with all discovered commands

#### Module Entry Point (toast/__main__.py)

Enables the application to be run as a module with `python -m toast`.

#### Helper Utilities (toast/helpers.py)

- Contains helper functions and custom UI elements
- `display_logo()`: Renders the ASCII logo with version
- `get_version()`: Retrieves version information from VERSION file
- `CustomHelpCommand` & `CustomHelpGroup`: Custom Click classes for enhanced help display

### Plugin System

The plugin system is based on Python's `importlib` and `pkgutil` modules, which enable dynamic loading of modules at runtime. This allows the application to be extended without modifying the core code.

#### Core Plugin Components

1. **BasePlugin (`plugins/base_plugin.py`)**
   - Abstract base class that all plugins must extend
   - Defines the interface for plugins
   - Provides registration mechanism for adding commands to the CLI

2. **Utilities (`plugins/utils.py`)**
   - Common utility functions used by multiple plugins
   - `select_from_list()`: Interactive selection using fzf for better user experience

### Plugin Structure

Each plugin follows a standard structure:
- Inherits from `BasePlugin`
- Defines a unique `name` and `help` text
- Implements `execute()` method containing the command logic
- Optionally overrides `get_arguments()` to define custom command arguments

### Plugin Loading Process

1. The application scans the `plugins` directory for Python modules
2. Each module is imported and examined for classes that extend `BasePlugin`
3. Valid plugin classes are instantiated and registered with the CLI
4. Click handles argument parsing and command execution

## Current Plugins

| Plugin | Command | Description |
|--------|---------|-------------|
| AmPlugin | am | Show AWS caller identity |
| CdwPlugin | cdw | Navigate to workspace directories |
| CtxPlugin | ctx | Manage Kubernetes contexts |
| EnvPlugin | env | Set environment with AWS profile |
| GitPlugin | git | Manage Git repositories |
| RegionPlugin | region | Set AWS region |
| SsmPlugin | ssm | Manage AWS SSM parameters |
| UpdatePlugin | update | Update CLI tool |

### Plugin Details

#### EnvPlugin (env command)

The `env` command handles AWS environment profile management:

1. **Environment Path Discovery**:
   - Looks for AWS_ENV_PATH in the .env file in the current directory
   - If not found, creates a path at ~/workspace/github.com/{username}/keys/env
   - Uses whoami to get the default username, but allows customization

2. **Profile Management**:
   - Lists and allows selection of profiles from the environment path
   - Loads environment variables from the selected profile file
   - Sets AWS_PROFILE environment variable

3. **Authentication Verification**:
   - Verifies credentials by calling AWS STS get-caller-identity
   - Uses jq to provide colorized JSON output of the AWS identity information
   - Displays AWS region if available

4. **File Structure**:
   - Environment profiles are stored as files in the env directory
   - Each file contains key=value pairs for environment variables

#### GitPlugin (git command)

The `git` command handles Git repository operations:

1. **Repository Path Validation**:
   - Validates that the current directory is in the ~/workspace/github.com/{username} format
   - Extracts username from the current path for repository operations

2. **Repository Cloning**:
   - Clones repositories from the user's GitHub account using the username extracted from path
   - Supports cloning to a specified target directory name (optional)
   - Format: `toast git repo_name clone` (기본) 또는 `toast git repo_name clone --target target_name` (대상 디렉토리 지정)

3. **Repository Removal**:
   - Safely removes repository directories with confirmation prompt
   - Format: `toast git repo_name rm`

4. **Path Management**:
   - Automatically constructs GitHub repository URLs based on extracted username
   - Manages repository paths within the workspace directory structure

#### SsmPlugin (ssm command)

The `ssm` command manages AWS SSM Parameter Store operations:

1. **Parameter Retrieval**:
   - Lists and allows selection of parameters with the `/toast/` prefix
   - Displays parameter value with automatic decryption for SecureString types
   - Shows parameter type and last modified date
   - Format: `toast ssm` (default action)

2. **Parameter Creation/Update**:
   - Adds `/toast/` prefix automatically to user-provided parameter names
   - Supports multiline value input (ended with Ctrl+D)
   - Stores parameters as SecureString type for sensitive information
   - Format: `toast ssm put`

3. **Parameter Removal**:
   - Lists and allows selection of parameters with the `/toast/` prefix
   - Confirms deletion before removing the parameter
   - Format: `toast ssm rm` (or `toast ssm remove`)

4. **User Interface**:
   - Uses fzf for interactive parameter selection
   - Provides confirmation prompts for destructive operations
   - Shows clear success/error messages

## Dependencies

The plugin system has the following external dependencies:
- Click: Command-line interface creation
- Python-Dotenv: Environment variable management from .env files
- External tools used by various plugins:
  - fzf: Interactive selection in terminal
  - jq: JSON processing for formatted output
  - aws-cli: AWS command line interface
  - kubectl: Kubernetes command line tool

## Adding New Plugins

To add a new plugin:
1. Create a new Python file in the `plugins` directory
2. Define a class that extends `BasePlugin`
3. Implement the required methods (`execute` and optionally `get_arguments`)
4. Set the `name` and `help` class variables

The plugin will be automatically discovered and loaded when the application starts.

## Benefits of the Plugin Architecture

- **Modularity**: Each command is isolated in its own module
- **Extensibility**: New commands can be added without modifying existing code
- **Maintainability**: Code is organized into logical components
- **Testability**: Plugins can be tested independently

## Packaging and Distribution

The project is packaged using standard Python packaging tools. The following files enable packaging and distribution:

1. **setup.py**: The main setup script that defines package metadata and dependencies
   - Current version: 3.0.0
   - Author: nalbam <byforce@gmail.com>
   - Main package requirements: click, python-dotenv

2. **setup.cfg**: Configuration file for package metadata and entry points
   - Organization: opspresso <info@opspresso.com>
   - License: GNU General Public License v3.0
   - Python compatibility: 3.6+

3. **pyproject.toml**: Defines build system requirements
   - Using setuptools and wheel

4. **MANIFEST.in**: Specifies additional files to include in the source distribution
   - Includes: README.md, LICENSE, VERSION, ARCHITECTURE.md, CNAME, favicon.ico, .mergify.yml

### Installation Methods

The package can be installed using pip:

```bash
# Install from PyPI (once published)
pip install toast-cli

# Install from local directory in development mode
pip install -e .

# Install from GitHub
pip install git+https://github.com/opspresso/toast-cli.git
```

### Building Distribution Packages

To build distribution packages:

```bash
# Install build requirements
pip install build

# Build source and wheel distributions
python -m build

# This will create:
# - dist/toast-cli-X.Y.Z.tar.gz (source distribution)
# - dist/toast_cli-X.Y.Z-py3-none-any.whl (wheel distribution)
```

### Publishing to PyPI

To publish the package to PyPI:

```bash
# Install twine
pip install twine

# Upload to PyPI
twine upload dist/*
```
