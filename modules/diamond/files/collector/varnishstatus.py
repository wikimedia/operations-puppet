"""
Collect request status code stats from varnish (by using varnishtop)

#### Dependencies

 * subprocess
"""

from diamond.collector import Collector
import subprocess


class VarnishStatusCollector(Collector):

    def get_default_config(self):
        """
        Returns the default collector settings
        """
        config = super(VarnishStatusCollector, self).get_default_config()
        config.update({
            'path': 'varnish',
            'bin':  '/usr/bin/varnishtop',
        })
        return config

    def collect(self):
        """
        Publishes stats to the configured path.
        By default /varnish/requests/###
        with one ### for each http status code
        """

        lines = self.poll()
        # Publish Metric
        for line in lines:
            parts = line.split()
            if (len(parts) == 3):
                self.publish('requests.' + parts[2], int(parts[0]))

    def poll(self):
        """
        This runs `varnishtop -b -i RxStatus -1`
        which returns output like the following:

          6053.00 RxStatus 200
          4204.00 RxStatus 302
           151.00 RxStatus 404
            45.00 RxStatus 301
            29.00 RxStatus 401
            18.00 RxStatus 500
             6.00 RxStatus 304

        The 1st column is a counter, 2nd is irrelevant
        3rd is the http status code

        This method returns the output from the command,
        split into element line per line.
        """
        try:
            command = [self.config['bin'], '-b', '-i', 'RxStatus', '-1']
            output = subprocess.check_output(command)

        except OSError:
            output = ""

        return output.splitlines()
