#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0

# quick integration test to assess basic functionality of the rewrite
# middleware (e.g. to test a swift upgrade)

# requirements:
# * a mediawiki installation to test thumb purge/(re)creation
# * python-requests
# * an existing original image

import unittest
import requests


PURGE_HOST = 'http://commons.wikimedia.org'


class WMFRewriteTest(unittest.TestCase):
    headers = {
        'Host': 'upload.wikimedia.org',
    }
    commons_path = '/wiki/File:Berlin_2014_077.JPG'
    thumb_path = '/wikipedia/commons/thumb/0/02/Berlin_2014_077.JPG/666px-Berlin_2014_077.JPG'
    thumb_path_swift = (
        '/v1/AUTH_mw/wikipedia-commons-local-thumb.02/0/02/'
        'Berlin_2014_077.JPG/666px-Berlin_2014_077.JPG')
    thumb_size = 87819

    originals = {
        "berlin": {
            "path": '/wikipedia/commons/0/02/Berlin_2014_077.JPG',
            "size": 1433230
        },
        "france": {
            "path": '/wikipedia/commons/3/3e/Drapeau_d%C3%A9partement_fr_Corr%C3%A8ze.svg',
            "size": 50282
        },
        "france-with-extra-slash": {
            "path": '/wikipedia/commons/3/3e/////Drapeau_d%C3%A9partement_fr_Corr%C3%A8ze.svg',
            "size": 50282
        },
        "ukraine": {
            "path": '/wikipedia/commons/b/b3/%D0%86%D0%B2%D0%B0%D0%BD%D0%BE-%D0%A4%D1%80%D0%B0%D0%BD%D0%BA%D1%96%D0%B2%D1%81%D1%8C%D0%BA%2C_%D0%93%D0%BE%D1%82%D0%B5%D0%BB%D1%8C_%D0%90%D0%B2%D1%81%D1%82%D1%80%D1%96%D1%8F%2C_%D0%B2%D1%83%D0%BB._%D0%A1%D1%96%D1%87%D0%BE%D0%B2%D0%B8%D1%85_%D0%A1%D1%82%D1%80%D1%96%D0%BB%D1%8C%D1%86%D1%96%D0%B2_12.jpg',  # noqa: E501
            "size": 5248160
            }
    }

    def test_remapping_originals(self):
        for name in self.originals:
            with self.subTest(name=name):
                r = requests.get('http://localhost' + self.originals[name]['path'],
                                 headers=self.headers)
                self.assertEqual(r.status_code, 200)
                self.assertEqual(int(r.headers['content-length']),
                                 self.originals[name]['size'])

    def test_remapping_thumb(self):
        r = requests.get('http://localhost' + self.thumb_path, headers=self.headers)
        self.assertEqual(r.status_code, 200)
        self.assertEqual(int(r.headers['content-length']), self.thumb_size)

    def test_nonexist_original(self):
        r = requests.get('http://localhost/wikipedia/commons/non_existant', headers=self.headers)
        self.assertEqual(r.status_code, 404)

    def test_nonexist_thumb(self):
        r = requests.get(
            'http://localhost/wikipedia/commons/thumb/non_existant',
            headers=self.headers)
        self.assertEqual(r.status_code, 404)

    # https://phabricator.wikimedia.org/T183902
    def test_invalid_range(self):
        headers = self.headers.copy()
        headers.update({'Range': 'bytes=%d-' % self.thumb_size})
        r = requests.get('http://localhost' + self.thumb_path, headers=headers)
        self.assertEqual(r.status_code, 416)

    def test_maybe_recreate_thumb(self):
        # An old thumbnail might have been dropped from swift, but it should
        # be regenerated on demand - in that case 404 the first time, then 200
        r = requests.get("http://localhost" + self.thumb_path_swift, headers=self.headers)
        self.assertIn(r.status_code, [404, 200])

        r = requests.get('http://localhost' + self.thumb_path, headers=self.headers)
        self.assertEqual(r.status_code, 200)
        self.assertEqual(int(r.headers['content-length']), self.thumb_size)

    def test_refuse_thumb_purge(self):
        # This used to be doable, but policy changed, so now you get 403
        r = requests.post(PURGE_HOST + self.commons_path, params={'action': 'purge'})
        self.assertEqual(r.status_code, 403)


if __name__ == '__main__':
    unittest.main()
