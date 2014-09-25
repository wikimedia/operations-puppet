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

parser = argparse.ArgumentParser(
    description=__doc__,
    formatter_class=argparse.ArgumentDefaultsHelpFormatter)

parser.add_argument('--server', default='127.0.0.1',
                    help='Gearman server to connect to')
parser.add_argument('--timeout', default='30', type=int,
                    help='timeout in seconds to connect to server')

subparsers = parser.add_subparsers(
    description='Gearman admin commands',
    dest='admin_command')
parser_status = subparsers.add_parser(
    'status',
    help='list functions status',
    formatter_class=argparse.RawTextHelpFormatter,
    description="""Output functions status:
\t1) function names
\t2) number of queued instances
\t3) number of currently running function
\t4) number of workers""")
parser_workers = subparsers.add_parser(
    'workers',
    help='list workers and their functions',
    description='Output workers registrated functions')

opts = parser.parse_args()

client = gear.Client('zuul-gearman.py')
client.addServer(opts.server)
client.waitForServer()
server = client.getConnection()

req_name = '%sAdminRequest' % opts.admin_command.lower().capitalize()
req = getattr(gear, req_name)()
exit_code = 1
try:
    server.sendAdminRequest(req, timeout=opts.timeout)
    print req.response
    exit_code = 0
except gear.TimeoutError:
    print "Server timeout exceeded (%s)" % opts.server
finally:
    exit(exit_code)
