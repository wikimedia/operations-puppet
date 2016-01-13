#!/usr/bin/env python

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
    original_path = '/wikipedia/commons/0/02/Berlin_2014_077.JPG'
    original_path_swift = '/v1/AUTH_mw/wikipedia-commons-local-public.02/Berlin_2014_077.JPG'
    original_size = 1433230
    thumb_path = '/wikipedia/commons/thumb/0/02/Berlin_2014_077.JPG/666px-Berlin_2014_077.JPG'
    thumb_path_swift = '/v1/AUTH_mw/wikipedia-commons-local-thumb.02/0/02/Berlin_2014_077.JPG/666px-Berlin_2014_077.JPG'
    thumb_size = 70195

    def test_remapping_originals(self):
        r = requests.get('http://localhost' + self.original_path, headers=self.headers)
        self.assertEquals(r.status_code, 200)
        self.assertEquals(int(r.headers['content-length']), self.original_size)

    def test_remapping_thumb(self):
        r = requests.get('http://localhost' + self.thumb_path, headers=self.headers)
        self.assertEquals(r.status_code, 200)
        self.assertEquals(int(r.headers['content-length']), self.thumb_size)

    def test_purge_thumb(self):
        r = requests.post(PURGE_HOST + self.commons_path, params={'action': 'purge'})
        self.assertEquals(r.status_code, 302)
        r = requests.get("http://localhost" + self.thumb_path_swift, headers=self.headers)
        self.assertEquals(r.status_code, 404)

    def test_purge_recreate_thumb(self):
        r = requests.post(PURGE_HOST + self.commons_path, params={'action': 'purge'})
        self.assertEquals(r.status_code, 302)

        r = requests.get("http://localhost" + self.thumb_path_swift, headers=self.headers)
        self.assertEquals(r.status_code, 404)

        r = requests.get('http://localhost' + self.thumb_path, headers=self.headers)
        self.assertEquals(r.status_code, 200)
        self.assertEquals(int(r.headers['content-length']), self.thumb_size)

    def test_nonexist_original(self):
        r = requests.get('http://localhost/wikipedia/commons/non_existant', headers=self.headers)
        self.assertEquals(r.status_code, 404)

    def test_nonexist_thumb(self):
        r = requests.get('http://localhost/wikipedia/commons/thumb/non_existant', headers=self.headers)
        self.assertEquals(r.status_code, 404)


if __name__ == '__main__':
    unittest.main()
