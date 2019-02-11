#!/usr/bin/python3
import argparse
import subprocess

parser = argparse.ArgumentParser(description='Sync DNS changes')
parser.add_argument('params', metavar='PARAM', nargs='+',
                    help='Parameter to pass to the remote command.')
parser.add_argument('--remote-servers', metavar='REMOTE_SERVER', nargs='+',
                    required=True, help='Remote servers to send command to.')
args = parser.parse_args()

for server in args.remote_servers:
    print(server, args.params)
    subprocess.run(
        [
            '/usr/bin/ssh',
            '-l',
            'acme-chief',
            server,
            '/usr/bin/sudo',
            '-u',
            'gdnsd',
            '/usr/bin/gdnsdctl',
            '--',
            # end of options because otherwise parameters beginning with a hyphen, like some acme
            # challenge values, will cause problems
            'acme-dns-01'
        ] + args.params,
        check=True,
        env={'SSH_AUTH_SOCK': '/run/keyholder/proxy.sock'}
    )
