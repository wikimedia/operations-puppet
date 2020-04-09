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
    def setUp(self):
        with open('modules/smart/files/tests/fixtures/smartctl_scan_open.txt', 'r') as f:
            self.smartctl_scan_open = f.read()
        with open('modules/smart/files/tests/fixtures/hpssacli_show_all_config.txt', 'r') as f:
            self.hpssacli_all_config_raw = f.read()
        with open('modules/smart/files/tests/fixtures/lsblk.txt', 'r') as f:
            self.lsblk_raw = f.read()

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

    def test_megaraid_get_pd(self):
        output = smart_data_dump.megaraid_parse(self.smartctl_scan_open)
        for pd in output:
            self.assertEqual(pd.driver, 'megaraid')
            self.assertEqual(pd.disk_id.split(',')[0], 'sat+megaraid')
            self.assertEqual(pd.smart_args[0], '-d')
            self.assertEqual(pd.smart_args[1].split(',')[0], 'sat+megaraid')
            self.assertEqual(pd.smart_args[2], '/dev/bus/0')

    def test_hpsa_get_pd(self):
        output = smart_data_dump.hpsa_parse(self.hpssacli_all_config_raw)
        for pd in output:
            self.assertEqual(pd.driver, 'cciss')
            self.assertEqual(pd.disk_id.split(',')[0], 'cciss')
            self.assertEqual(pd.smart_args[0], '-d')
            self.assertEqual(pd.smart_args[1].split(',')[0], 'cciss')
            self.assertEqual(pd.smart_args[2], '/dev/sda')

    def test_noraid_get_pd(self):
        output = smart_data_dump.noraid_parse(self.lsblk_raw)
        for pd in output:
            self.assertEqual(pd.driver, 'noraid')
            self.assertIn(pd.disk_id, ['sda', 'sdb'])
            self.assertEqual(pd.smart_args[0], '-d')
            self.assertEqual(pd.smart_args[1], 'auto')
            self.assertIn(pd.smart_args[2], ['/dev/sda', '/dev/sdb'])
