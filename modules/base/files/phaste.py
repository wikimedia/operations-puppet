#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
  phaste: Phabricator paste tool

"""
from argparse import ArgumentParser
import fileinput
import json
from urllib.request import Request, urlopen
from urllib.parse import urlencode


class Conduit(object):
    """A wrapper around Phabricator's Conduit API."""

    def __init__(self, phab, token):
        self.phab = phab
        self.token = token

    def call(self, method, **params):
        """Call the conduit API."""
        params['__conduit__'] = {'token': self.token}
        data = {
            'params': json.dumps(params),
            'output': 'json',
        }
        url = '%s/api/%s' % (self.phab, method)
        headers = {'User-Agent': 'wmf/phaste.py urllib (root@wikimedia.org)'}
        req = Request(url, data=urlencode(data).encode('utf-8'), headers=headers)
        with urlopen(req) as resp:
            resp_data = json.loads(resp.read().decode('utf-8'))
        if resp_data.get('error_info'):
            raise RuntimeError('%(error_code)s: %(error_info)s' % resp_data)
        return resp_data['result']


parser = ArgumentParser(description='Post input into a Phabricator Paste, and output the URL.')
parser.add_argument('--config', default='/etc/phaste.conf',
                    help='Path to the configuration file with credentials')
parser.add_argument('-t', '--title', help='Set a title on the paste')
parser.add_argument('files', metavar='FILE', nargs='*', help='Files to read; if empty, stdin')
args = parser.parse_args()

with open(args.config) as f:
    config = json.load(f)

p = Conduit(phab=config['phab'], token=config['token'])
transactions = [{"type": "text", "value": ''.join(fileinput.input(args.files))}]
if args.title is not None:
    transactions.append({"type": "title", "value": args.title})
call_kwargs = {"transactions": transactions}
res = p.call('paste.edit', **call_kwargs)
url = '%s/P%s' % (p.phab, res['object']['id'])
print(url)
