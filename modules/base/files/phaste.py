#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
  phaste: Phabricator paste tool

"""
from argparse import ArgumentParser
import fileinput
import hashlib
import json
import time
from urllib.request import Request, urlopen
from urllib.parse import urlencode


class Conduit(object):
    """A wrapper around Phabricator's Conduit API."""

    def __init__(self, phab, user, cert):
        self.phab = phab
        self.user = user
        self.cert = cert
        self.credentials = None

    def _do_request(self, method, data):
        url = '%s/api/%s' % (self.phab, method)
        headers = {'User-Agent': 'wmf/phaste.py urllib (root@wikimedia.org)'}
        req = Request(url, data=urlencode(data).encode('utf-8'), headers=headers)
        with urlopen(req) as resp:
            data = resp.read().decode('utf-8')
            resp_data = json.loads(data)
        if resp_data.get('error_info'):
            raise RuntimeError('%(error_code)s: %(error_info)s' % resp_data)
        return resp_data['result']

    def _get_credentials(self):
        if self.credentials is None:
            token = int(time.time())
            signature = hashlib.sha1((str(token) + self.cert).encode()).hexdigest()
            params = {
                'client': 'phaste',
                'clientVersion': 0,
                'user': self.user,
                'authToken': token,
                'authSignature': signature,
            }
            data = {
                'params': json.dumps(params),
                'output': 'json',
                '__conduit__': 'true',
            }
            self.credentials = self._do_request('conduit.connect', data)
        return self.credentials

    def call(self, method, **params):
        """Call the conduit API."""
        params['__conduit__'] = self._get_credentials()
        data = {
            'params': json.dumps(params),
            'output': 'json',
        }
        return self._do_request(method, data)


parser = ArgumentParser(description='Post input into a Phabricator Paste, and output the URL.')
parser.add_argument('--config', default='/etc/phaste.conf',
                    help='Path to the configuration file with credentials')
parser.add_argument('-t', '--title', help='Set a title on the paste')
parser.add_argument('files', metavar='FILE', nargs='*', help='Files to read; if empty, stdin')
args = parser.parse_args()

with open(args.config) as f:
    config = json.load(f)

p = Conduit(phab=config['phab'], user=config['user'], cert=config['cert'])
call_kwargs = {}
call_kwargs['content'] = ''.join(fileinput.input(args.files))
if args.title is not None:
    call_kwargs['title'] = args.title
res = p.call('paste.create', **call_kwargs)
print(res['uri'])
