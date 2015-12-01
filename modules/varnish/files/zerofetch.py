#!/usr/bin/python

# This script fetches the Zero carriers and proxies JSON data
#  and deposits it on-disk for vmod_netmapper consumption.
# As a general rule, if everything doesn't go perfectly, an
#  uncaught exception kills the script, and no real action
#  that affects the runtime netmapper is taken until the
#  very end, so exception-deaths are safe from the runtime
#  netmapper's perspective.

import os
import string
import argparse
import tempfile
import json
import filecmp
import requests  # Note: this isn't in the standard library


# The ZeroFetcher class handles all of the MediaWiki API login+fetch
#   operations necessary to pull down the JSON data we need.
class ZeroFetcher:
    # The core method that handles actual network requests from
    #   all the other methods (including the constructor!)
    def _apiJSON(self, method, action, params={}):
        params.update({'action': action})
        resp = getattr(self.sess, method)(self.baseurl, params=params)
        if resp.status_code != requests.codes.ok:
            raise Exception('Bad response code ' +
                            str(resp.status_code) +
                            ' from API request for ' +
                            action)
        try:
            resp_data = json.loads(resp.content)
        except ValueError:
            raise Exception('Invalid JSON response from API request for ' +
                            action)
        return resp_data

    # Object instantiation does an immediate two-phase login...
    def __init__(self, site, username, password):
        self.baseurl = site + '/w/api.php'
        self.sess = requests.session()
        self.sess.params = {'format': 'json'}
        self.sess.headers = {'Cache-Control': 'no-cache'}
        self.logged_in = False
        login_params = {'lgname': username, 'lgpassword': password}
        login1_data = self._apiJSON('post', 'login', login_params)
        if login1_data['login']['result'] != 'NeedToken':
            raise Exception('API login phase1 gave result ' +
                            login1_data['login']['result'] +
                            ', expected "NeedToken"')
        login_params['lgtoken'] = login1_data['login']['token']
        login2_data = self._apiJSON('post', 'login', login_params)
        if login2_data['login']['result'] != 'Success':
            raise Exception('API login phase2 gave result ' +
                            login2_data['login']['result'] +
                            ', expected "Success"')
        self.logged_in = True

    # Logout method, which only acts if we're currently logged-in
    def logout(self):
        if self.logged_in:
            self._apiJSON('get', 'logout')
            self.logged_in = False

    # Destructor handles logout if logged-in.  Note that an exception during
    #  construction still calls the destructor.
    def __del__(self):
        self.logout

    # Fetches zeroportal data of type "ztype" as JSON data
    def zeroconf(self, ztype):
        return self._apiJSON('get', 'zeroportal', {'type': ztype})


# For use with argparse to validate the output dir exists and is a directory
def check_isdir(d):
    if not os.path.isdir(d):
        raise Exception(d + ' is not a directory!')
    return d


def main():
    # Start of execution, set umask and parse arguments:
    #  -s is of the form "https://zero.wikimedia.org"
    #  -d is the output directory, e.g. "/var/netmapper"
    #  -a is the authfile, which should contain a single line
    #      that looks like "username:password"
    os.umask(022)
    ap = argparse.ArgumentParser()
    ap.add_argument('-s', '--site', required=True)
    ap.add_argument('-d', '--directory', required=True, type=check_isdir)
    ap.add_argument('-a', '--authfile', required=True,
                    type=argparse.FileType('rU'))
    args = ap.parse_args()
    (username, password) = args.authfile.readline().rstrip('\n').split(':')

    # The zeroconf types we will fetch
    ztypes = ['carriers', 'proxies']

    # Fetch carriers and proxies data over the network.  Note this will
    #   throw exceptions if anything is amiss, and validates that the
    #   returned data is at least legal JSON.
    fetcher = ZeroFetcher(args.site, username, password)
    json_data = {}
    for ztype in ztypes:
        json_data[ztype] = fetcher.zeroconf(ztype)
    fetcher.logout()

    # Write all JSON data files into a temp subdirectory of the output dir
    #  and validate them via vnm_validate.  Sets up the renames dict with
    #  temp paths as keys and final paths as values, for use in the rename
    #  block below.
    tempdir = tempfile.mkdtemp(dir=args.directory)
    renames = {}
    for ztype in ztypes:
        out_temp = os.path.join(tempdir, ztype + '.json')
        renames[out_temp] = os.path.join(args.directory, ztype + '.json')
        json.dump(json_data[ztype], file(out_temp, 'w'))
        if os.system('/usr/bin/vnm_validate ' + out_temp + ' >/dev/null 2>&1'):
            raise Exception('Validation of ' + out_temp +
                            ' via vnm_validate failed')

    # Rename all of the JSON files into the actual output directory,
    #  IFF the contents are different from the existing file (so as
    #  not to trip the mtime-watching reload code in vmod_netmapper
    #  unnecessarily)
    for temp in renames:
        if (not os.path.exists(renames[temp]) or
                not filecmp.cmp(temp, renames[temp])):
            os.rename(temp, renames[temp])
        else:
            os.remove(temp)

    # Remove the tempdir, which should be empty now via rename-or-remove above
    os.rmdir(tempdir)


if __name__ == "__main__":
    main()
