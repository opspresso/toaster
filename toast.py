#!/usr/bin/env python3

import click
import subprocess
import os

def run_am():
    try:
        result = subprocess.run(["aws", "sts", "get-caller-identity"], capture_output=True, text=True)
        if result.returncode == 0:
            formatted_json = subprocess.run(["jq", "-C", "."], input=result.stdout, capture_output=True, text=True)
            click.echo(formatted_json.stdout)
        else:
            click.echo("Error fetching AWS caller identity.")
    except Exception as e:
        click.echo(f"Error fetching AWS caller identity: {e}")

def run_cdw():
    workspace_dir = os.path.expanduser("~/workspace")
    if not os.path.exists(workspace_dir):
        os.makedirs(workspace_dir)

    result = subprocess.run(["find", workspace_dir, "-mindepth", "1", "-maxdepth", "2", "-type", "d"], capture_output=True, text=True)
    directories = sorted(result.stdout.splitlines())

    if not directories:
        click.echo("No directories found in ~/workspace.")
        return

    selected_dir = select_from_list(directories, "Select a directory")

    if selected_dir:
        click.echo(selected_dir)
    else:
        click.echo("No directory selected.", err=True)

def run_ctx():
    result = subprocess.run(["kubectl", "config", "get-contexts", "-o=name"], capture_output=True, text=True)
    if result.returncode != 0:
        click.echo("Error fetching Kubernetes contexts. Is kubectl configured correctly?")
        return

    contexts = sorted(result.stdout.splitlines())
    contexts.append("[New...]")
    if len(contexts) > 1:
        contexts.append("[Del...]")

    selected_ctx = select_from_list(contexts, "Select a Kubernetes context")

    if selected_ctx == "[New...]":
        result = subprocess.run(["aws", "eks", "list-clusters", "--query", "clusters", "--output", "text"], capture_output=True, text=True)
        if result.returncode != 0:
            click.echo("Error fetching EKS clusters.")
            return

        clusters = sorted(result.stdout.split())
        if not clusters:
            click.echo("No EKS clusters found.")
            return

        selected_cluster = select_from_list(clusters, "Select an EKS cluster")

        if selected_cluster:
            subprocess.run(["aws", "eks", "update-kubeconfig", "--name", selected_cluster, "--alias", selected_cluster])
            click.echo(f"Updated kubeconfig for {selected_cluster}")
        else:
            click.echo("No cluster selected.")
    elif selected_ctx == "[Del...]":
        delete_contexts = [ctx for ctx in contexts if ctx not in ("[New...]", "[Del...]")]
        delete_contexts.append("[All...]")
        selected_to_delete = select_from_list(delete_contexts, "Select a context to delete")
        if selected_to_delete == "[All...]":
            subprocess.run(["kubectl", "config", "unset", "contexts"])
            click.echo("Deleted all Kubernetes contexts.")
        elif selected_to_delete:
            subprocess.run(["kubectl", "config", "delete-context", selected_to_delete])
            click.echo(f"Deleted Kubernetes context: {selected_to_delete}")
        else:
            click.echo("No context selected for deletion.")
    elif selected_ctx:
        subprocess.run(["kubectl", "config", "use-context", selected_ctx])
        click.echo(f"Switched to Kubernetes context: {selected_ctx}")
    else:
        click.echo("No context selected.")

def run_env(env_name):
    click.echo(f"Setting environment to {env_name}")

def select_from_list(options, prompt="Select an option"):
    try:
        fzf_proc = subprocess.run(["fzf", "--height=15", "--reverse", "--border", "--prompt", prompt+": "], input="\n".join(options), capture_output=True, text=True)
        return fzf_proc.stdout.strip()
    except Exception as e:
        click.echo(f"Error selecting from list: {e}")
        return None

def run_region():
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

def run_update():
    click.echo("Updating CLI tool")

@click.group()
def toast():
    pass

@toast.command()
def am():
    run_am()

@toast.command()
def cdw():
    run_cdw()

@toast.command()
@click.argument('env_name')
def env(env_name):
    run_env(env_name)

@toast.command()
def region():
    run_region()

@toast.command()
def ctx():
    run_ctx()

@toast.command()
def update():
    run_update()

if __name__ == "__main__":
    toast()
