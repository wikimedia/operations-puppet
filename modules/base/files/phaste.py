#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
  phaste: Phabricator paste tool

"""
import sys
reload(sys)
sys.setdefaultencoding('utf-8')

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
        req = urllib2.urlopen(url, data=urllib.urlencode(data))
        resp = json.load(req)
        if resp.get('error_info'):
            raise RuntimeError('%(error_code)s: %(error_info)s' % resp)
        return resp['result']

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


with open('/etc/phaste.conf') as f:
    config = json.load(f)

p = Conduit(phab=config['phab'], user=config['user'], cert=config['cert'])
res = p.call('paste.create', content=''.join(fileinput.input()))
print res['uri']
