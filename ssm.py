import boto3
import argparse
import json
import sys
import subprocess

def put_parameter(name, value):
    ssm = boto3.client('ssm')
    response = ssm.put_parameter(
        Name=f"/toast/{name}",
        Value=value,
        Type='SecureString',
        Overwrite=True
    )
    print("====================")
    print("Stored successfully.")
    print("====================")

def get_parameter(name):
    ssm = boto3.client('ssm')
    try:
        response = ssm.get_parameter(Name=name, WithDecryption=True)
        print("====================")
        print(response['Parameter']['Value'])
        print("====================")
    except ssm.exceptions.ParameterNotFound:
        print("====================")
        print("Error: Parameter not found.")
        print("====================")

def list_parameters():
    ssm = boto3.client('ssm')
    response = ssm.describe_parameters(Filters=[{'Key': 'Name', 'Values': ['/toast/']}])
    parameters = [param['Name'] for param in response['Parameters']]
    print("====================")
    for param in parameters:
        print(param)
    print("====================")

def select_command():
    commands = ['put', 'get', 'list']
    result = subprocess.run(['fzf', '--height=10', '--reverse'], input='\n'.join(commands), text=True, capture_output=True)
    return result.stdout.strip() if result.returncode == 0 else None

def select_parameter():
    ssm = boto3.client('ssm')
    response = ssm.describe_parameters(Filters=[{'Key': 'Name', 'Values': ['/toast/']}])
    parameters = [param['Name'] for param in response['Parameters']]
    if not parameters:
        print("====================")
        print("No parameters found.")
        print("====================")
        sys.exit(1)
    result = subprocess.run(['fzf', '--height=10', '--reverse'], input='\n'.join(parameters), text=True, capture_output=True)
    return result.stdout.strip() if result.returncode == 0 else None

def main():
    parser = argparse.ArgumentParser(description="CLI Key Store using AWS SSM Parameter Store")
    subparsers = parser.add_subparsers(dest='command')

    put_parser = subparsers.add_parser('put', help='Store a key-value pair')
    put_parser.add_argument('key', type=str, help='Key name', nargs='?')
    put_parser.add_argument('value', nargs='?', type=str, help='Value (use - for multiline input)', default=None)

    get_parser = subparsers.add_parser('get', help='Retrieve a value by key')
    get_parser.add_argument('key', type=str, help='Key name', nargs='?')

    list_parser = subparsers.add_parser('list', help='List keys with prefix /toast/')

    args, unknown = parser.parse_known_args()

    if not args.command:
        args.command = select_command()

    if args.command == 'put':
        if not hasattr(args, 'key') or not args.key:
            args.key = input("Enter key: ")
        if not hasattr(args, 'value') or args.value is None or args.value == "-":
            print("Enter multi-line value (Ctrl-D to save, Ctrl-C to cancel):")
            args.value = sys.stdin.read().strip()
        put_parameter(args.key, args.value)
    elif args.command == 'get':
        if not hasattr(args, 'key') or not args.key:
            args.key = select_parameter()
        get_parameter(args.key)
    elif args.command == 'list':
        list_parameters()
    else:
        parser.print_help()

if __name__ == "__main__":
    main()
