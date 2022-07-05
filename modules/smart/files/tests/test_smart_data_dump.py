# SPDX-License-Identifier: Apache-2.0
import unittest
from unittest import mock
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
        with open('modules/smart/files/tests/fixtures/hpssacli_show_all_config_detail.txt',
                  'r') as f:
            self.hpssacli_all_config_raw = f.read()
        with open('modules/smart/files/tests/fixtures/lsblk.json', 'r') as f:
            self.lsblk_raw = f.read()
        with open('modules/smart/files/tests/fixtures/smartctl_info.txt', 'r') as f:
            self.smartctl_info = f.read()
        with open('modules/smart/files/tests/fixtures/smartctl_attributes.txt', 'r') as f:
            self.smartctl_attributes = f.read()
        with open('modules/smart/files/tests/fixtures/lsscsi.txt', 'r') as f:
            self.lsscsi = f.read()

    def test_good_cmd(self):
        output = smart_data_dump._check_output('/bin/echo "this is a test"')
        self.assertEqual(output, 'this is a test')

    def test_bad_cmd(self):
        with self.assertLogs('smart_data_dump', level='DEBUG'):
            with self.assertRaises(subprocess.CalledProcessError):
                smart_data_dump._check_output('nonexistentcommand')

    @mock.patch.dict('os.environ', {'LC_MESSAGES': 'C'})
    def test_suppressed_errors_cmd(self):
        output = smart_data_dump._check_output('nonexistentcommand', suppress_errors=True)
        self.assertRegex(
            output,
            '/usr/bin/timeout: failed to run command'
            ' .nonexistentcommand.: No such file or directory')

    def test_timeout(self):
        with self.assertLogs('smart_data_dump', level='DEBUG'):
            with self.assertRaises(subprocess.CalledProcessError):
                smart_data_dump._check_output('/usr/bin/sleep 2', 1)

    def test_megaraid_parse(self):
        output = smart_data_dump.megaraid_parse(self.smartctl_scan_open)
        for gd in output:
            self.assertEqual(gd.target, '/dev/bus/0')
            self.assertEqual(gd.name.split(',')[0], 'sat+megaraid')
            self.assertEqual(gd.type, gd.name)

    def test_hpsa_parse(self):
        output = smart_data_dump.hpsa_parse(
            self.hpssacli_all_config_raw,
            smart_data_dump.lsscsi_parse(self.lsscsi)
        )
        for controller in output:
            self.assertIn(controller.target, ['/dev/sg0', '/dev/sg3'])
            if controller.target == '/dev/sg0':
                self.assertEqual(len(controller.disks.keys()), 14)
            if controller.target == '/dev/sg3':
                self.assertEqual(len(controller.disks.keys()), 24)
            self.assertEqual(controller.type, 'cciss')

    def test_noraid_parse(self):
        output = smart_data_dump.noraid_parse(self.lsblk_raw)
        exp_blk_devs = [
            smart_data_dump.DISK(name="sda", target="/dev/sda", type=None),
            smart_data_dump.DISK(name="sdb", target="/dev/sdb", type=None),
            smart_data_dump.DISK(name="nvme0", target="/dev/nvme0", type=None),
        ]
        blk_dev_count = 0
        for i, gd in enumerate(output):
            self.assertEqual(exp_blk_devs[i], gd)
            blk_dev_count += 1
        self.assertEqual(blk_dev_count, len(exp_blk_devs))

    def test_parse_smart_info(self):
        smart_healthy, model, firmware, serial = smart_data_dump \
            ._parse_smart_info(self.smartctl_info)
        self.assertEqual(smart_healthy, 1)
        self.assertEqual(serial, 'REDACTEDSERIAL')
        self.assertEqual(model, 'REDACTEDMODEL')
        self.assertEqual(firmware, 'F1RMW4R3')

    def test_parse_smart_attributes(self):
        output = smart_data_dump._parse_smart_attributes(self.smartctl_attributes)
        self.assertDictEqual(output, {
            'raw_read_error_rate': '4294967295',
            'reallocated_sector_ct': '4',
            'power_on_hours': '14116',
            'power_cycle_count': '48',
            'read_soft_error_rate': '153953102725119',
            'used_rsvd_blk_cnt_tot': '2',
            'unused_rsvd_blk_cnt_tot': '9839',
            'program_fail_cnt_total': '0',
            'erase_fail_count_total': '1',
            'end_to_end_error': '0',
            'temperature_celsius': '24',
            'hardware_ecc_recovered': '0',
            'current_pending_sector': '0',
            'offline_uncorrectable': '0',
            'udma_crc_error_count': '0',
            'available_reservd_space': '0',
            'media_wearout_indicator': '791062',
            'total_lbas_written': '791062',
            'total_lbas_read': '164795'
        })

    def test_lsscsi_parse(self):
        output = smart_data_dump.lsscsi_parse(self.lsscsi)
        self.assertListEqual(list(output.keys()), ['51402ec000146540', '5001438040efb200'])
        self.assertListEqual(list(output.values()), ['/dev/sg0', '/dev/sg3'])
