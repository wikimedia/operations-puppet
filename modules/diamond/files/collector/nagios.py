# coding=utf8
import diamond.collector
import json
import os
import subprocess


class NagiosCollector(diamond.collector.Collector):
    def collect(self):
        for fname in os.listdir('/etc/diamond/nagios.d'):
            with open(os.path.join('/etc/diamond/nagios.d', fname)) as config_file:
                config_data = json.load(config_file)
                exit_code = subprocess.call(config_data['command'])
                self.publish(config_data['name'], exit_code)
