#!/usr/bin/env python2
"""
Test case to verify that the refreshDomainRedirects
script was run to re-generate redirects.conf from
redirects.dat.

This test will make sure that redirects.conf was regenerated
properly, and if not, it will do it for you!
"""

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
        # Get current contents
        old = self.get_contents(fname)
        # Run the refresh script, possibly modifying the file
        subprocess.call([os.path.join(this_dir, 'refreshDomainRedirects')])
        # Get the new contents and make sure it's still the same
        new = self.get_contents(fname)
        self.assertEqual(
            old,
            new,
            'redirects.conf not regenerated. Run ./refreshDomainRedirects.'
        )

if __name__ == '__main__':
    unittest.main()
