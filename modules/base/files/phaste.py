#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
  phaste: Phabricator paste tool

"""
import sys
reload(sys)
sys.setdefaultencoding('utf-8')

from argparse import ArgumentParser
import fileinput
import hashlib
import json
import time
import urllib
import urllib2


class Conduit(object):
    """A wrapper around Phabricator's Conduit API."""

    def __init__(self, phab, user, cert):
        self.phab = phab
        self.user = user
        self.cert = cert
        self.credentials = None

    def _do_request(self, method, data):
        url = '%s/api/%s' % (self.phab, method)
        headers = {'User-Agent': 'wmf/phaste.py urllib2 (root@wikimedia.org)'}
        req = urllib2.Request(url, data=urllib.urlencode(data), headers=headers)
        resp = urllib2.urlopen(req)
        resp_data = json.load(resp)
        if resp_data.get('error_info'):
            raise RuntimeError('%(error_code)s: %(error_info)s' % resp_data)
        return resp_data['result']

    def _get_credentials(self):
        if self.credentials is None:
            token = int(time.time())
            signature = hashlib.sha1(str(token) + self.cert).hexdigest()
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
print res['uri']
