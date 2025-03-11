#!/usr/bin/env python3

import click
import subprocess
import os
import json
from pathlib import Path
from toast.plugins.base_plugin import BasePlugin
from toast.plugins.utils import select_from_list

class EnvPlugin(BasePlugin):
    """Plugin for 'env' command - sets environment."""

    name = "env"
    help = "Set environment with AWS profile"

    @classmethod
    def get_arguments(cls, func):
        func = click.argument('env_name', required=False)(func)
        return func

    @classmethod
    def execute(cls, env_name=None, **kwargs):
        # Load or create toast config
        toast_json_path = Path(os.path.expanduser("~/.toast.json"))
        toast_config = cls._load_or_create_config(toast_json_path)

        # Check if 1Password CLI is available
        op_available = cls._check_op_cli_available()

        # If 1Password is available, use it for profile management
        if op_available:
            cls._use_1password_for_profiles(toast_json_path, toast_config, env_name)
        else:
            # Fall back to file-based profiles if 1Password isn't available
            cls._use_file_based_profiles(toast_json_path, toast_config, env_name)

    @classmethod
    def _check_op_cli_available(cls):
        """Check if 1Password CLI is available"""
        try:
            result = subprocess.run(["op", "--version"], capture_output=True, text=True)
            if result.returncode == 0:
                click.echo(f"1Password CLI detected: {result.stdout.strip()}")
                return True
            return False
        except FileNotFoundError:
            click.echo("1Password CLI not found. Using file-based profiles.")
            return False

    @classmethod
    def _load_or_create_config(cls, config_path):
        """Load existing config or create a new one"""
        config = {}

        # Create ~/.toast.json if it doesn't exist
        if not config_path.exists():
            config_path.parent.mkdir(parents=True, exist_ok=True)
            click.echo(f"Creating new configuration file: {config_path}")
            with open(config_path, 'w') as json_file:
                json.dump(config, json_file, indent=2)
        else:
            try:
                with open(config_path, 'r') as json_file:
                    config = json.load(json_file)
            except json.JSONDecodeError:
                click.echo("Error: ~/.toast.json is not a valid JSON file")
                click.echo("Creating new configuration file")
                with open(config_path, 'w') as json_file:
                    json.dump(config, json_file, indent=2)
            except Exception as e:
                click.echo(f"Error reading ~/.toast.json: {e}")

        return config

    @classmethod
    def _save_config(cls, config_path, config):
        """Save config to file"""
        with open(config_path, 'w') as json_file:
            json.dump(config, json_file, indent=2)

    @classmethod
    def _use_1password_for_profiles(cls, config_path, config, env_name):
        """Use 1Password CLI for profile management"""
        # Ensure the user is signed in to 1Password
        signin_result = subprocess.run(["op", "signin", "--check"], capture_output=True, text=True)
        if signin_result.returncode != 0:
            click.echo("Not signed in to 1Password. Please sign in:")
            subprocess.run(["op", "signin"])

        # Always list available vaults
        vaults_result = subprocess.run(["op", "vault", "list", "--format", "json"],
                                      capture_output=True, text=True)
        if vaults_result.returncode != 0:
            click.echo("Error fetching 1Password vaults")
            return

        try:
            vaults = json.loads(vaults_result.stdout)
            vault_names = [vault['name'] for vault in vaults]
            selected_vault = select_from_list(vault_names, "Select a 1Password vault")
            if not selected_vault:
                click.echo("No vault selected. Exiting.")
                return

            click.echo(f"Using vault: {selected_vault}")
        except json.JSONDecodeError:
            click.echo("Error parsing 1Password vault list")
            return

        # List secure notes in the selected vault
        items_result = subprocess.run(
            ["op", "item", "list", "--vault", selected_vault, "--categories", "secure_note", "--format", "json"],
            capture_output=True, text=True
        )

        if items_result.returncode != 0:
            click.echo(f"Error fetching secure notes from vault '{selected_vault}'")
            return

        try:
            items = json.loads(items_result.stdout)
            if not items:
                click.echo(f"No secure notes found in vault '{selected_vault}'")
                return

            # Use existing env_name or select from list
            if not env_name:
                item_names = [item['title'] for item in items]
                selected_item = select_from_list(item_names, "Select an AWS profile secure note")
                if not selected_item:
                    click.echo("No profile selected. Exiting.")
                    return
                env_name = selected_item

            # Find the selected item
            selected_item_id = None
            for item in items:
                if item['title'] == env_name:
                    selected_item_id = item['id']
                    break

            if not selected_item_id:
                click.echo(f"Profile '{env_name}' not found in vault '{selected_vault}'")
                return

            # Get the secure note content
            item_result = subprocess.run(
                ["op", "item", "get", selected_item_id, "--format", "json"],
                capture_output=True, text=True
            )

            if item_result.returncode != 0:
                click.echo(f"Error fetching secure note '{env_name}'")
                return

            item_data = json.loads(item_result.stdout)

            # Extract environment variables from the note
            note_content = None
            for field in item_data.get('fields', []):
                if field.get('label') == 'notesPlain' or field.get('id') == 'notesPlain':
                    note_content = field.get('value', '')
                    break

            if not note_content:
                click.echo(f"No content found in secure note '{env_name}'")
                return

            # Parse environment variables from note content
            aws_access_key_id = None
            aws_secret_access_key = None
            aws_region = None

            for line in note_content.splitlines():
                if '=' in line:
                    key, value = line.strip().split('=', 1)
                    os.environ[key] = value

                    # Capture AWS credentials for config file
                    if key == "AWS_ACCESS_KEY_ID":
                        aws_access_key_id = value
                    elif key == "AWS_SECRET_ACCESS_KEY":
                        aws_secret_access_key = value
                    elif key == "AWS_REGION":
                        aws_region = value

            # Update AWS configuration
            cls._update_aws_configuration(env_name, aws_access_key_id, aws_secret_access_key, aws_region)

            # Display results
            click.echo(f"Set environment to {env_name}")
            if "AWS_REGION" in os.environ:
                click.echo(f"AWS Region: {os.environ['AWS_REGION']}")

            # Display AWS identity info
            cls._display_aws_identity()

        except json.JSONDecodeError:
            click.echo("Error parsing 1Password items data")
            return

    @classmethod
    def _use_file_based_profiles(cls, config_path, config, env_name):
        """Use traditional file-based profile management"""
        env_path = config.get("AWS_ENV_PATH")

        # If AWS_ENV_PATH is not set, create it
        if not env_path:
            # Get username using whoami command
            result = subprocess.run(["whoami"], capture_output=True, text=True)
            default_username = result.stdout.strip()

            # Create github.com directory if it doesn't exist
            github_dir = os.path.expanduser("~/workspace/github.com")
            if not os.path.exists(github_dir):
                os.makedirs(github_dir, exist_ok=True)
                click.echo(f"Created directory: {github_dir}")

            # Ask user to input username or use provided env_name as username
            if not env_name:
                click.echo(f"Enter GitHub username (default: {default_username}):")
                input_username = input().strip()
                username = input_username if input_username else default_username
            else:
                # Check if env_name might be a profile name rather than username
                potential_path = os.path.expanduser(f"~/workspace/github.com/{default_username}/keys/env/{env_name}")
                if os.path.exists(potential_path):
                    # env_name is likely a profile name, use default username
                    username = default_username
                else:
                    # env_name is likely a username
                    username = env_name

            # Set AWS_ENV_PATH
            env_path = os.path.expanduser(f"~/workspace/github.com/{username}/keys/env")

            # Create directory if it doesn't exist
            env_dir = os.path.dirname(env_path)
            if not os.path.exists(env_dir):
                os.makedirs(env_dir, exist_ok=True)
                click.echo(f"Created directory: {env_dir}")

            # Update config and save
            config["AWS_ENV_PATH"] = env_path
            cls._save_config(config_path, config)

            # Export the environment variable
            os.environ["AWS_ENV_PATH"] = env_path

        # List available profiles if env_path exists
        if os.path.exists(env_path):
            try:
                profiles = [f for f in os.listdir(env_path) if os.path.isfile(os.path.join(env_path, f))]

                if not profiles:
                    click.echo(f"No profiles found in {env_path}")
                    return

                if not env_name or env_name not in profiles:
                    selected_profile = select_from_list(profiles, "Select an AWS profile")
                    if selected_profile:
                        env_name = selected_profile
                    else:
                        click.echo("No profile selected.")
                        return

                # Load the selected profile and environment variables
                profile_path = os.path.join(env_path, env_name)
                aws_access_key_id = None
                aws_secret_access_key = None
                aws_region = None

                if os.path.exists(profile_path):
                    with open(profile_path, 'r') as f:
                        for line in f:
                            if '=' in line:
                                key, value = line.strip().split('=', 1)
                                os.environ[key] = value

                                # Capture AWS credentials for config file
                                if key == "AWS_ACCESS_KEY_ID":
                                    aws_access_key_id = value
                                elif key == "AWS_SECRET_ACCESS_KEY":
                                    aws_secret_access_key = value
                                elif key == "AWS_REGION":
                                    aws_region = value

                # Update AWS configuration
                cls._update_aws_configuration(env_name, aws_access_key_id, aws_secret_access_key, aws_region)

                # Display results
                click.echo(f"Set environment to {env_name}")
                if "AWS_REGION" in os.environ:
                    click.echo(f"AWS Region: {os.environ['AWS_REGION']}")

                # Display AWS identity info
                cls._display_aws_identity()

            except Exception as e:
                click.echo(f"Error setting environment: {e}")
        else:
            click.echo(f"Environment path does not exist: {env_path}")

    @classmethod
    def _update_aws_configuration(cls, env_name, aws_access_key_id, aws_secret_access_key, aws_region):
        """Update AWS configuration files with credentials"""
        if not aws_access_key_id or not aws_secret_access_key:
            return  # Skip if credentials are not available

        # Ensure AWS CLI config directory exists
        aws_config_dir = os.path.expanduser("~/.aws")
        if not os.path.exists(aws_config_dir):
            os.makedirs(aws_config_dir, exist_ok=True)

        # Update credentials file
        if aws_access_key_id and aws_secret_access_key:
            credentials_file = os.path.join(aws_config_dir, "credentials")

            # Update the named profile
            cls._update_aws_file(credentials_file, env_name, {
                "aws_access_key_id": aws_access_key_id,
                "aws_secret_access_key": aws_secret_access_key
            })

            # Also update default profile
            cls._update_aws_file(credentials_file, "default", {
                "aws_access_key_id": aws_access_key_id,
                "aws_secret_access_key": aws_secret_access_key
            })

            click.echo(f"Updated default AWS profile with {env_name} credentials")

            # Update config file with region if available
            if aws_region:
                config_file = os.path.join(aws_config_dir, "config")

                # Update the named profile
                cls._update_aws_file(config_file, f"profile {env_name}", {
                    "region": aws_region
                })

                # Also update default profile
                cls._update_aws_file(config_file, "default", {
                    "region": aws_region
                })

        # Set the AWS_PROFILE environment variable
        os.environ["AWS_PROFILE"] = env_name
        click.echo(f"Set AWS_PROFILE={env_name}")

    @classmethod
    def _display_aws_identity(cls):
        """Display AWS caller identity information using AWS CLI"""
        try:
            result = subprocess.run(["aws", "sts", "get-caller-identity"], capture_output=True, text=True)
            if result.returncode == 0:
                formatted_json = subprocess.run(["jq", "-C", "."], input=result.stdout, capture_output=True, text=True)
                click.echo(formatted_json.stdout)
            else:
                click.echo("Error fetching AWS caller identity.")
        except Exception as e:
            click.echo(f"Error fetching AWS identity: {e}")

    @staticmethod
    def _update_aws_file(file_path, section_name, entries):
        """Update AWS credentials or config file with given section and entries"""
        config_content = ""
        section_exists = False

        # Read existing content if file exists
        if os.path.exists(file_path):
            with open(file_path, 'r') as f:
                config_content = f.read()

        # Parse sections
        sections = {}
        current_section = None
        for line in config_content.splitlines():
            line = line.strip()
            if line.startswith('[') and line.endswith(']'):
                current_section = line[1:-1]
                sections[current_section] = []
            elif current_section is not None:
                sections[current_section].append(line)

        # Update or add section
        sections[section_name] = [f"{key} = {value}" for key, value in entries.items()]

        # Write updated content
        with open(file_path, 'w') as f:
            for section, lines in sections.items():
                f.write(f"[{section}]\n")
                for line in lines:
                    f.write(f"{line}\n")
                f.write("\n")  # Empty line between sections
