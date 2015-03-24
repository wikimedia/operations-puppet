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
            'path': 'cluster',
            'bin':  '/usr/bin/varnishtop',
        })
        return config

    def collect(self):
        """
        Publishes stats to the configured path.
        e.g. /availability/cluster/staging/#
        with one # for each http status code
        """
        group_by_type = {}
        lines = self.poll()
        # Publish Metric
        for line in lines:
            parts = line.split()
            if (len(parts) == 3):
                code = parts[2]
                type = code[:1] + 'xx'
                count = int(float(parts[0]))
                group_by_type[type] = group_by_type.setdefault(type, 0) + count
                self.publish_counter(code, count)

        for k, v in group_by_type.iteritems():
            self.publish_counter(k, v)

        if '5xx' in group_by_type and '2xx' in group_by_type:
            success_count = group_by_type['2xx']
            fail_count = group_by_type['5xx']
            if '3xx' in group_by_type:
                success_count += group_by_type['3xx']
            if '4xx' in group_by_type:
                fail_count += group_by_type['4xx']
            self.publish_counter('ok', success_count)
            self.publish_counter('fail', fail_count)
            # calculate the error ratio (ratio of fail to success)
            ratio = float(fail_count) / float(success_count)
            # publish it as a percentage
            self.publish_gague('availability', 100 - ratio)

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
            command = [self.config['bin'], "-b", "-i", "RxStatus", "-1"]
            output = subprocess.check_output(command)

        except Exception as e:
            self.log.error("Error: %s", e)
            output = ""

        return output.splitlines()
