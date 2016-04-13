# coding=utf-8
"Collect keyholder status code"
import subprocess
import diamond.collector


class KeyholderStatusCollector(diamond.collector.Collector):
    def collect(self):
        child = subprocess.Popen('/usr/bin/sudo /usr/lib/nagios/plugins/check_keyholder')
        self.publish('keyholder_status', child.wait())
