# coding=utf-8
"Collect keyholder status code"
import subprocess
import diamond.collector


class KeyholderStatusCollector(diamond.collector.Collector):
    def collect(self):
        child = subprocess.Popen([
            '/usr/bin/sudo',
            '/usr/lib/nagios/plugins/check_keyholder'
        ])
        # Publish return code:
        # * 0 for success
        # * 2 for unarmed/failed to connect
        # * 3 for lack of permissions
        self.publish('keyholder_status', child.wait())
