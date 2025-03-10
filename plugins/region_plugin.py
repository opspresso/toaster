#!/usr/bin/env python3

import click
import subprocess
from plugins.base_plugin import BasePlugin
from plugins.utils import select_from_list

class RegionPlugin(BasePlugin):
    """Plugin for 'region' command - sets AWS region."""

    name = "region"
    help = "Set AWS region"

    @classmethod
    def execute(cls, **kwargs):
        try:
            result = subprocess.run(["aws", "ec2", "describe-regions", "--query", "Regions[].RegionName", "--output", "text"], capture_output=True, text=True)
            regions = sorted(result.stdout.split())
            if not regions:
                click.echo("No regions found.")
                return

            selected_region = select_from_list(regions, "Select AWS Region")

            if selected_region:
                subprocess.run(["aws", "configure", "set", "default.region", selected_region])
                subprocess.run(["aws", "configure", "set", "default.output", "json"])
                click.echo(f"Set AWS region to {selected_region}")
            else:
                click.echo("No region selected.")
        except Exception as e:
            click.echo(f"Error fetching AWS regions: {e}")
