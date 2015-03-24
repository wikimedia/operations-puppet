"""
Collect request status code metrics from varnish (by using varnishtop)
Used to collect beta / staging cluster availability metrics

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
            'path': 'availability',
            'bin':  '/usr/bin/varnishtop',
        })
        return config

    def collect(self):
        """
        Publishes stats to the configured path.
        e.g. /deployment-prep/hostname/availability/#
        with one # for each http status code
        """
        group_by_type = {'2xx': 0, '3xx': 0, '4xx': 0, '5xx': 0}
        total = 0
        lines = self.poll()
        # Publish Metric
        for line in lines:
            parts = line.split()
            if (len(parts) == 3):
                count = int(float(parts[0]))
                total += count
                code = parts[2]
                type = code[:1] + 'xx'
                group_by_type[type] = group_by_type.setdefault(type, 0) + count
                self.publish_counter(code, count)

        for k, v in group_by_type.iteritems():
            if v > 0:
                self.publish_counter(k, v)

        success_count = group_by_type['2xx'] + group_by_type['3xx']

        # calculate the percentage of successful out of the total request count
        if success_count > 0:
            self.publish_counter('ok', success_count)
            ratio = float(success_count) / float(total)
            self.publish_gauge('availability', 100 * ratio)

    def poll(self):
        """
        This runs `varnishtop -c -i TxStatus -1`
        which returns output like the following:

         58888.00 TxStatus 200
          1050.00 TxStatus 302
            65.00 TxStatus 404
            40.00 TxStatus 503
            29.00 TxStatus 204
            19.00 TxStatus 401
            18.00 TxStatus 301
             3.00 TxStatus 304

        The 1st column is a request status counter, 2nd is irrelevant
        3rd is the http status code

        This method returns the output from the command,
        split into 1 element per line.
        """

        try:
            command = [self.config['bin'], "-c", "-i", "TxStatus", "-1"]
            output = subprocess.check_output(command)

        except Exception as e:
            self.log.error("Error: %s", e)
            output = ""

        return output.splitlines()
