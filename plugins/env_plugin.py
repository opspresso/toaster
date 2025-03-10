#!/usr/bin/env python3

import click
import subprocess
import os
import dotenv
from pathlib import Path
from plugins.base_plugin import BasePlugin
from plugins.utils import select_from_list

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
        # Try to get AWS_ENV_PATH from .env file
        dotenv_path = Path('.env')
        env_path = None

        if dotenv_path.exists():
            dotenv.load_dotenv(dotenv_path)
            env_path = os.environ.get("AWS_ENV_PATH")

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

            # Update .env file
            with open(dotenv_path, 'a+') as f:
                f.seek(0)
                content = f.read()
                if "AWS_ENV_PATH" not in content:
                    if content and not content.endswith('\n'):
                        f.write('\n')
                    f.write(f"AWS_ENV_PATH={env_path}\n")

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

                # Ensure AWS CLI config directory exists
                aws_config_dir = os.path.expanduser("~/.aws")
                if not os.path.exists(aws_config_dir):
                    os.makedirs(aws_config_dir, exist_ok=True)

                # Update AWS config and credentials files if we have the necessary info
                if aws_access_key_id and aws_secret_access_key:
                    # Update credentials file for both profile name and default
                    credentials_file = os.path.join(aws_config_dir, "credentials")

                    # Update the named profile
                    cls._update_aws_file(credentials_file, env_name, {
                        "aws_access_key_id": aws_access_key_id,
                        "aws_secret_access_key": aws_secret_access_key
                    })

                    # Also update default profile with the same credentials
                    cls._update_aws_file(credentials_file, "default", {
                        "aws_access_key_id": aws_access_key_id,
                        "aws_secret_access_key": aws_secret_access_key
                    })

                    click.echo(f"Updated default AWS profile with {env_name} credentials")

                    # Update config file for both profile name and default
                    config_file = os.path.join(aws_config_dir, "config")
                    config_entries = {}
                    if aws_region:
                        config_entries["region"] = aws_region

                    if config_entries:
                        # Update the named profile
                        cls._update_aws_file(config_file, f"profile {env_name}", config_entries)

                        # Also update default profile
                        cls._update_aws_file(config_file, "default", config_entries)

                # Set the AWS_PROFILE environment variable
                os.environ["AWS_PROFILE"] = env_name
                click.echo(f"Set AWS_PROFILE={env_name}")

                click.echo(f"Set environment to {env_name}")

                # Display region if available
                if "AWS_REGION" in os.environ:
                    click.echo(f"AWS Region: {os.environ['AWS_REGION']}")

                # Display profile information using AWS CLI
                try:
                    subprocess.run(["aws", "sts", "get-caller-identity"])
                except Exception as e:
                    click.echo(f"Error fetching AWS identity: {e}")

            except Exception as e:
                click.echo(f"Error setting environment: {e}")
        else:
            click.echo(f"Environment path does not exist: {env_path}")

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
