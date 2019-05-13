#!/usr/bin/python3 -Es
# Drain an oslo.message rabbitmq queue
#
# The contents of this file are subject to the Mozilla Public License
# Version 1.1 (the 'License'); you may not use this file except in
# compliance with the License. You may obtain a copy of the License at
# http://www.mozilla.org/MPL/
#
# Software distributed under the License is distributed on an 'AS IS'
# basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
# License for the specific language governing rights and limitations
# under the License.
#
# The Original Code is RabbitMQ Management Plugin.
#
# The Initial Developer of the Original Code is GoPivotal, Inc.
# Copyright (c) 2010-2015 Pivotal Software, Inc.  All rights reserved.
#
# Modified by Bryan Davis <bd808@wikimedia.org>
# Copyright (c) 2017 Wikimedia Foundation and contributors

import argparse
import base64
import http.client
import json
import socket
import sys
import urllib.parse


def eprint(*args, **kwargs):
    # disable qa as we are testing with python2 flake8 T184435
    print(*args, file=sys.stderr, **kwargs)  # noqa: E999


def die(s):
    eprint('*** {}'.format(s))
    exit(1)


def http_req(username, password, verb, path, body=None):
    path = '/api%s' % path
    conn = http.client.HTTPConnection('localhost', 15672)
    credentials = '{}:{}'.format(username, password)
    b = credentials.encode()
    headers = {
        'Authorization': 'Basic {}'.format(
            base64.b64encode(b).decode('ascii')),
    }
    if body:
        headers['Content-Type'] = 'application/json'
    try:
        conn.request(verb, path, body, headers)
    except socket.error as e:
        die('Could not connect: {0}'.format(e))
    resp = conn.getresponse()
    resp_body = resp.read().decode('utf-8')
    if resp.status == 400:
        die(json.loads(resp_body)['reason'])
    if resp.status == 401:
        die('Access refused: {}'.format(path))
    if resp.status == 404:
        # Rabbitmq manages queues dynamically so
        # the existence of a queue may depend on a message
        # ever needing to be delivered to it.  Even
        # necessary queues are often created on-demand.
        eprint('Queue not found!')
        return json.dumps('')
    if resp.status == 301:
        url = urllib.parse.urlparse(resp.getheader('location'))
        [host, port] = url.netloc.split(':')
        return http_req(username,
                        password,
                        verb,
                        url.path + '?' + url.query,
                        body)
    if resp.status < 200 or resp.status > 400:
        raise Exception(
            'Received {:d} {} for path {}\n{}'.format(
                resp.status, resp.reason, path, resp_body))
    return resp_body


def http_json(username, password, verb, path, body=None):
    return json.loads(http_req(username, password, verb, path, body))


def message_count(username, password, queue):
    out = http_json(username,
                    password,
                    'GET',
                    '/queues/%2F/{}'.format(queue))
    if not out:
        return None
    return out['messages_ready']


def main():
    parser = argparse.ArgumentParser(
        description='Drain an oslo.message rabbitmq queue')
    group = parser.add_mutually_exclusive_group()
    group.add_argument(
        '--dry-run', dest='requeue', action='store_true',
        help='return messages to the queue after printing')
    group.add_argument(
        '--silent', dest='silent', action='store_true',
        help='silent mode')
    parser.add_argument(
        'queue', metavar='QUEUE', nargs=1,
        help='queue to read messages from')
    parser.add_argument(
        '--username', default='drainqueue',
        help='username to connect to rabbitmq')
    parser.add_argument(
        '--password', default='',
        help='password to connect to rabbitmq')

    args = parser.parse_args()
    queue = args.queue[0]
    username = args.username
    password = args.password

    if args.silent:
        http_req(username,
                 password,
                 'DELETE',
                 '/queues/%2F/{}/contents'.format(queue))

    else:
        ready = message_count(username, password, queue)
        if ready is None:
            return
        print("message count is {}".format(ready))
        while ready > 0:
            msgs = http_json(
                username,
                password,
                'POST',
                '/queues/%2F/{}/get'.format(queue),
                json.dumps({
                    'count': 1000,  # Limit response size
                    'requeue': args.requeue,
                    'encoding': 'auto'
                })
            )

            for m in msgs:
                payload = json.loads(m['payload'])
                msg = json.loads(payload['oslo.message'])
                print(json.dumps(msg))

            if args.requeue:
                ready = 0  # prevent infinte loops
            else:
                ready = message_count(username, password, queue)


if __name__ == '__main__':
    main()
