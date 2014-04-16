#!/usr/bin/python

import os
import string
import argparse
import tempfile
import json
import requests

class ZeroFetcher:
    def __init__(self, site, username, password):
        self.baseurl = site + '/w/api.php'
        self.sess = requests.session()
        self.sess.params = { 'format': 'json' }
        self.sess.headers = { 'Cache-Control': 'no-cache' }
        self.logged_in = False
        login_params = { 'lgname': username, 'lgpassword': password }
        login1_data = self._apiJSON('post', 'login', login_params)
        if login1_data['login']['result'] != 'NeedToken':
            raise Exception('API login phase1 gave result ' + login1_data['login']['result'] + ', expected "NeedToken"')
        login_params['lgtoken'] = login1_data['login']['token']
        login2_data = self._apiJSON('post', 'login', login_params)
        if login2_data['login']['result'] != 'Success':
            raise Exception('API login phase2 gave result ' + login2_data['login']['result'] + ', expected "Success"')
        self.logged_in = True

    def __del__(self):
        if self.logged_in:
            self._apiJSON('get', 'logout')

    def _apiJSON(self, method, action, params = {}):
        params.update({ 'action': action })
        resp = getattr(self.sess, method)(self.baseurl, params = params)
        if resp.status_code != requests.codes.ok:
            raise Exception('Bad response code ' + resp.status_code + ' from API request for ' + action)
        try:
            resp_data = json.loads(resp.text)
        except ValueError:
            raise Exception('Invalid JSON response from API request for ' + action)
        return resp_data

    def zeroconf(self, ztype):
        return self._apiJSON('get', 'zeroconfig', { 'type': ztype })

def check_isdir(d):
    if not os.path.isdir(d):
        raise Exception(d + ' is not a directory!')
    return d

def same_file_contents(f1, f2):
    if(os.stat(f1).st_size != os.stat(f2).st_size):
        return False
    fd1 = open(f1, 'rb')
    fd2 = open(f2, 'rb')
    while True:
        b1 = fd1.read(4096)
        b2 = fd2.read(4096)
        if b1 != b2:
            return False
        if not b1:
            return True

def main():
    os.umask(022)

    ap = argparse.ArgumentParser()
    ap.add_argument('-s', '--site', required=True)
    ap.add_argument('-d', '--directory', required=True, type=check_isdir)
    ap.add_argument('-a', '--authfile', required=True, type=argparse.FileType('rU'))
    args = ap.parse_args()
    (username, password) = args.authfile.readline().rstrip('\n').split(':')

    fetcher = ZeroFetcher(args.site, username, password)
    tempdir = tempfile.mkdtemp(dir=args.directory)
    renames = {}
    for ztype in ['carriers', 'proxies']:
        data = fetcher.zeroconf(ztype)
        out_temp = os.path.join(tempdir, ztype + '.json')
        json.dump(data, file(out_temp, 'w'))
        if os.system('/usr/bin/vnm_validate ' + out_temp + ' >/dev/null 2>&1'):
            raise Exception('Validation of ' + out_temp + ' via vnm_validate failed')
        renames[out_temp] = os.path.join(args.directory, ztype + '.json');
    for temp in renames:
        if not same_file_contents(temp, renames[temp]):
            os.rename(temp, renames[temp])
        else:
            os.remove(temp)
    os.rmdir(tempdir)

if __name__ == "__main__":
    main()
