# coding=utf8
import diamond.collector
import json
import os
import subprocess


class NagiosCollector(diamond.collector.Collector):
    def collect(self):
        for f in os.listdir('/etc/diamond/nagios.d'):
            data = json.load(open('/etc/diamond/nagios.d/' + f))
            child = subprocess.Popen(data['command'])
            self.publish(data['name'], child.wait())