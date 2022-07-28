#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
import argparse
import sys

from ClusterShell.Task import task_self

parser = argparse.ArgumentParser(description='Sync DNS changes')
parser.add_argument('params', metavar='PARAM', nargs='+',
                    help='Parameter to pass to the remote command.')
parser.add_argument('--remote-servers', metavar='REMOTE_SERVER', nargs='+',
                    required=True, help='Remote servers to send command to.')
args = parser.parse_args()

remote_servers_string = ','.join(args.remote_servers)
cmd = '{sudo} {gdnsdctl} -- {challenge_type} {challenges}'.format(sudo='/usr/bin/sudo -u gdnsd',
                                                                  gdnsdctl='/usr/bin/gdnsdctl',
                                                                  challenge_type='acme-dns-01',
                                                                  challenges=' '.join(args.params))
task = task_self()
task.set_info('ssh_options', '-oIdentityAgent=/run/keyholder/proxy.sock')
worker = task.run(cmd, nodes=remote_servers_string, timeout=60)
ret = 0
for remote_server in args.remote_servers:
    ret |= worker.node_retcode(remote_server)

sys.exit(ret)
