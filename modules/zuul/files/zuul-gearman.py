#!/usr/bin/env python
"""Easily send admin requests to a Gearman server."""
# Copyright 2014 Antoine "hashar" Musso
# Copyright 2014 Wikimedia Foundation Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

import argparse
import gear
import sys

map_cmd_class = {
    'cancel job': 'CancelJobAdminRequest',
    'show jobs': 'ShowJobsAdminRequest',
    'show unique jobs': 'ShowUniqueJobsAdminRequest',
    'status': 'StatusAdminRequest',
    'version': 'VersionAdminRequest',
    'workers': 'WorkersAdminRequest',
}


class GearAdminRequestAction(argparse.Action):

    """
    Validates a user command
    """

    def __call__(self, parser, namespace, values, option_string=None):
        if not len(values) > 0:
            parser.error('must be given a command')

        cmd = ' '.join([v.lower() for v in values])
        if cmd not in map_cmd_class:
            parser.error("invalid command '%s'" % cmd)
        setattr(namespace, self.dest, cmd)


parser = argparse.ArgumentParser(
    description=__doc__,
    formatter_class=argparse.RawTextHelpFormatter)

parser.add_argument('--server', default='127.0.0.1',
                    help='Gearman server to connect to')
parser.add_argument('--timeout', default='30', type=int,
                    help='timeout in seconds to connect to server')

parser.add_argument(
    'command',
    help="\n".join(sorted(map_cmd_class)),
    nargs=argparse.REMAINDER,
    action=GearAdminRequestAction)

opts = parser.parse_args()

req_class = map_cmd_class[opts.command]
try:
    req = getattr(gear, req_class)()
except AttributeError:
    sys.stderr.write("Command '%s' not implemented.\n"
                     "gear.%s does not exist.\n"
                     % (opts.command, req_class))
    exit(1)

client = gear.Client('zuul-gearman.py')
client.addServer(opts.server)
client.waitForServer()
server = client.getConnection()

exit_code = 1
try:
    server.sendAdminRequest(req, timeout=opts.timeout)
    print req.response
    exit_code = 0
except gear.TimeoutError:
    print "Server timeout exceeded (%s)" % opts.server
finally:
    exit(exit_code)
