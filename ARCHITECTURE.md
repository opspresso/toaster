# Toast-cli Architecture

[![Website](https://img.shields.io/badge/Website-Visit-blue)](https://toast.sh/)
[![PyPI](https://img.shields.io/pypi/v/toast-cli)](https://pypi.org/project/toast-cli/)

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
  ├── VERSION             # Version information
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
          ├── git_plugin.py
          ├── region_plugin.py
          └── utils.py
```

## Components

### Main Application Components

#### Main Entry Point (toast/__init__.py)

The main entry point of the application is responsible for:
- Dynamically discovering and loading plugins from the `toast.plugins` package
- Registering plugin commands with the CLI interface using Click
- Running the CLI with all discovered commands
- Providing core commands like `version` to display the current version

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

## Core Commands

| Command | Description |
|--------|-------------|
| version | Display the current version of toast-cli |

## Current Plugins

| Plugin | Command | Description |
|--------|---------|-------------|
| AmPlugin | am | Show AWS caller identity |
| CdwPlugin | cdw | Navigate to workspace directories |
| CtxPlugin | ctx | Manage Kubernetes contexts |
| EnvPlugin | env | Manage AWS profiles |
| GitPlugin | git | Manage Git repositories |
| LocalPlugin | local | Manage .env.local files with AWS SSM integration |
| RegionPlugin | region | Set AWS region |

### Plugin Details

#### EnvPlugin (env command)

The `env` command manages AWS profiles:

1. **Profile Discovery**:
   - Reads profiles from the `~/.aws/credentials` file
   - Shows list of available AWS profiles for selection

2. **Profile Selection**:
   - Uses interactive fzf selection for better user experience
   - Allows users to select from all configured AWS profiles

3. **Default Profile Management**:
   - Sets the selected profile as the default AWS profile
   - Preserves authentication information including access key, secret key, and session token
   - Simplifies working with multiple AWS accounts

#### RegionPlugin (region command)

The `region` command manages AWS regions:

1. **Current Region Display**:
   - Shows the currently configured AWS region before selection
   - Provides clear feedback on the active region

2. **Region Discovery**:
   - Fetches available AWS regions using the AWS CLI
   - Presents a sorted list of all available regions

3. **Region Selection**:
   - Uses interactive fzf selection for better user experience
   - Allows users to select from all available AWS regions

4. **Region Configuration**:
   - Sets the selected region as the default AWS region
   - Updates AWS CLI configuration with the selected region
   - Sets JSON as the default output format

#### GitPlugin (git command)

The `git` command handles Git repository operations:

1. **Repository Path Validation**:
   - Validates that the current directory is in the ~/workspace/github.com/{username} format
   - Extracts username from the current path for repository operations

2. **Repository Cloning**:
   - Clones repositories from the user's GitHub account using the username extracted from path
   - Supports cloning to a specified target directory name (optional)
   - Format: `toast git repo_name clone` (default) or `toast git repo_name clone --target target_name` (specify target directory)

3. **Repository Removal**:
   - Safely removes repository directories with confirmation prompt
   - Format: `toast git repo_name rm`

4. **Branch Creation**:
   - Creates a new git branch in the specified repository
   - Automatically changes to the new branch using git checkout -b
   - Format: `toast git repo_name branch --branch branch_name` (default) or `toast git repo_name b -b branch_name` (shortened command)

5. **Pull Repository Changes**:
   - Pulls the latest changes from the remote repository
   - Synchronizes the local repository with updates from the remote
   - Supports rebase option with `--rebase` or `-r` flag
   - Format: `toast git repo_name pull` (default) or `toast git repo_name p` (shortened command)
   - With rebase: `toast git repo_name pull --rebase` or `toast git repo_name p -r`

6. **Path Management**:
   - Automatically constructs GitHub repository URLs based on extracted username
   - Manages repository paths within the workspace directory structure

## Dependencies

The plugin system has the following external dependencies:
- Click: Command-line interface creation
- pkg_resources: Resource access within Python packages (included in setuptools)
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
   - Author: nalbam <byforce@gmail.com>
   - Main package requirements: click

2. **setup.cfg**: Configuration file for package metadata and entry points
   - License: GNU General Public License v3.0
   - Python compatibility: 3.6+
   - Main package requirement: click

3. **pyproject.toml**: Defines build system requirements
   - Using setuptools and wheel

4. **MANIFEST.in**: Specifies additional files to include in the source distribution
   - Includes: README.md, LICENSE, VERSION, ARCHITECTURE.md, CNAME, favicon.ico, .mergify.yml

### Installation Methods

The package can be installed using pip:

```bash
# Install from PyPI
pip install toast-cli

# Install from local directory in development mode
pip install -e .

# Install from GitHub
pip install git+https://github.com/opspresso/toast-cli.git
```

The package is available on PyPI at https://pypi.org/project/toast-cli/

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
