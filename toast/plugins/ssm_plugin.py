#!/usr/bin/env python3

import click
import boto3
import subprocess
import os
from toast.plugins.base_plugin import BasePlugin
from toast.plugins.utils import select_from_list

class SsmPlugin(BasePlugin):
    """Plugin for 'ssm' command - runs AWS SSM commands."""

    name = "ssm"
    help = "Run AWS SSM Parameter Store commands"

    @classmethod
    def get_arguments(cls, func):
        """Define command arguments."""
        func = click.argument('action', required=False)(func)
        return func

    @classmethod
    def execute(cls, action=None, **_):
        """Execute SSM commands."""
        if action == 'put':
            cls.put_parameter()
        elif action == 'remove' or action == 'rm':
            cls.remove_parameter()
        else:
            # Default behavior is to get a parameter
            cls.get_parameter()

    @classmethod
    def get_parameter(cls):
        """Get and display parameter value."""
        try:
            ssm_client = boto3.client('ssm')

            # Get all parameters with /toast/ prefix using paginator
            paginator = ssm_client.get_paginator('describe_parameters')
            parameter_names = []

            for page in paginator.paginate(
                ParameterFilters=[
                    {'Key': 'Name', 'Option': 'BeginsWith', 'Values': ['/toast/']}
                ]
            ):
                for param in page['Parameters']:
                    parameter_names.append(param['Name'])

            if not parameter_names:
                click.echo("No parameters found with prefix '/toast/'")
                return

            # Sort parameter names for better display
            parameter_names.sort()

            # Let user select a parameter
            selected = select_from_list(parameter_names, "Select parameter")

            if not selected:
                click.echo("No parameter selected")
                return

            # Get the selected parameter with decryption
            response = ssm_client.get_parameter(
                Name=selected,
                WithDecryption=True
            )

            # Display the parameter value with dividers
            click.echo(f"\nParameter: {selected}")
            click.echo(f"Type: {response['Parameter']['Type']}")
            if 'LastModifiedDate' in response['Parameter']:
                click.echo(f"Last Modified: {response['Parameter']['LastModifiedDate']}")

            # Display value with dividers above and below
            click.echo("\n" + "-" * 40)
            click.echo(response['Parameter']['Value'])
            click.echo("-" * 40)

        except Exception as e:
            click.echo(f"Error getting parameter: {e}")

    @classmethod
    def put_parameter(cls):
        """Add or update a parameter."""
        try:
            # Get key from user
            key = click.prompt("Enter parameter name (without /toast/ prefix)")
            full_key = f"/toast/{key}"

            # Get multiline input for value
            click.echo("Enter parameter value (press Ctrl+D when done):")
            value_lines = []

            try:
                while True:
                    line = input()
                    value_lines.append(line)
            except EOFError:
                pass

            value = "\n".join(value_lines)

            # Inform user about the action
            click.echo(f"Saving '{full_key}' as SecureString parameter...")

            # Save to SSM
            ssm_client = boto3.client('ssm')
            ssm_client.put_parameter(
                Name=full_key,
                Value=value,
                Type='SecureString',
                Overwrite=True
            )

            click.echo(f"Parameter '{full_key}' saved successfully")

        except Exception as e:
            click.echo(f"Error saving parameter: {e}")

    @classmethod
    def remove_parameter(cls):
        """Remove a parameter."""
        try:
            ssm_client = boto3.client('ssm')

            # Get all parameters with /toast/ prefix
            paginator = ssm_client.get_paginator('describe_parameters')
            parameter_names = []

            for page in paginator.paginate(
                ParameterFilters=[
                    {'Key': 'Name', 'Option': 'BeginsWith', 'Values': ['/toast/']}
                ]
            ):
                for param in page['Parameters']:
                    parameter_names.append(param['Name'])

            if not parameter_names:
                click.echo("No parameters found with prefix '/toast/'")
                return

            # Sort parameter names for better display
            parameter_names.sort()

            # Let user select a parameter to remove
            selected = select_from_list(parameter_names, "Select parameter to remove")

            if not selected:
                click.echo("No parameter selected")
                return

            # Confirm before removal
            if not click.confirm(f"Are you sure you want to delete '{selected}'?"):
                click.echo("Operation cancelled")
                return

            # Remove the parameter
            ssm_client.delete_parameter(Name=selected)
            click.echo(f"Parameter '{selected}' deleted successfully")

        except Exception as e:
            click.echo(f"Error removing parameter: {e}")
