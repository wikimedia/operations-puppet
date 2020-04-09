import unittest
import subprocess
try:
    import smart_data_dump
except ImportError:
    # hack to make pylint work.
    import os
    import sys
    sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
    import smart_data_dump


class TestSmartDataDump(unittest.TestCase):

    def test_good_cmd(self):
        output = smart_data_dump._check_output('/bin/echo "this is a test"')
        self.assertEqual(output, 'this is a test')

    def test_bad_cmd(self):
        with self.assertRaises(subprocess.CalledProcessError):
            smart_data_dump._check_output('nonexistentcommand')

    def test_suppressed_errors_cmd(self):
        output = smart_data_dump._check_output('nonexistentcommand', suppress_errors=True)
        self.assertEqual(output, '/usr/bin/timeout: failed to run command'
                                 ' ‘nonexistentcommand’: No such file or directory')

    def test_timeout(self):
        with self.assertRaises(subprocess.CalledProcessError):
            smart_data_dump._check_output('/usr/bin/sleep 2', 1)
