"""
Collect request status code stats from varnish (by using varnishtop)

#### Dependencies

 * subprocess
"""
import diamond.collector
import subprocess

class VarnishStatusCollector(diamond.collector.Collector):

    def get_default_config(self):
        """
        Returns the default collector settings
        """
        config = super(VarnishStatusCollector, self).get_default_config()
        config.update({
            'path':            'varnish',
            'bin':             '/usr/bin/varnishtop',
        })
        return config

    def collect(self):
        lines = self.poll().splitlines()
        # Publish Metric
        for line in lines:
            parts = line.split()
            self.publish('requests.'+parts[2], int(parts[0]))

    def poll(self):
        try:
            command = [self.config['bin'], '-b', '-i', 'RxStatus', '-1']

            output = subprocess.Popen(command,
                                      stdout=subprocess.PIPE).communicate()[0]
        except OSError:
            output = ""

        return output
