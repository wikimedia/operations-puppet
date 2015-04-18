#!/usr/bin/env python2

import os
import subprocess
import unittest


class RedirectsDatTest(unittest.TestCase):
    def get_contents(self, fname):
        with open(fname) as f:
            text = f.read()
        return text

    def test_redirects_dat(self):
        this_dir = os.path.dirname(__file__)
        fname = os.path.join(this_dir, '../redirects.conf')
        old = self.get_contents(fname)
        subprocess.call([os.path.join(this_dir, 'refreshDomainRedirects')])
        new = self.get_contents(fname)
        self.assertEqual(old, new, 'redirects.conf not regenerated. Run ./refreshDomainRedirects.')

if __name__ == '__main__':
    unittest.main()
