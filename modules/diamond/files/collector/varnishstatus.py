"""
Collect request status code metrics from varnish (by using varnishtop)
Also used to collect beta / staging cluster availability metrics.

If run on the CLI (instead of by Diamond), this will print out request status
metrics on stdout.

#### Dependencies

 * subprocess
"""

from diamond.collector import Collector
import subprocess


def poll_varnishtop(varnishtop='/usr/bin/varnishtop', varnishname=None):
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
        command = [varnishtop, "-c", "-i", "TxStatus", "-1"]
        if varnishname:
            command += ["-n", varnishname]

        output = subprocess.check_output(command)

    except Exception as e:
        self.log.error("Error: %s", e)
        output = ""

    return output.splitlines()

def get_status_counts(varnishtop='/usr/bin/varnishtop', varnishname=None):
    """
    Parses the return from poll_varnishtop and returns a dict with request HTTP
    status counts grouped by by individual HTTP status codes, as well as status
    code types.  In addition, 'ok' is the number of 2xx + 3xx requests, 'total'
    is the total number of requests, and 'availability' is the percent 'ok'
    requests served.
    """
    status_counts = {
        '2xx': 0,
        '3xx': 0,
        '4xx': 0,
        '5xx': 0,
        'ok': 0,
        'total': 0,
        'availability': 0.0
    }

    # Publish Metric
    for line in poll_varnishtop(varnishtop, varnishname):
        parts = line.split()
        if (len(parts) == 3):
            count = int(float(parts[0]))

            # Increment total number of requests seen.
            status_counts['total'] = status_counts.setdefault('total', 0) + count

            # Increment number of requests with this HTTP status code
            status_code = parts[2]
            status_counts[status_code] = status_counts.setdefault(status_code, 0) + count

            # Increment number of requests with this HTTP status code type
            status_type = status_code[:1] + 'xx'
            status_counts[status_type] = status_counts.setdefault(status_type, 0) + count

    status_counts['ok'] = status_counts['2xx'] + status_counts['3xx']

    # calculate the percentage of successful out of the total request count
    if  status_counts['ok'] > 0 and status_counts['total'] > 0:
        status_counts['availability'] = 100 * (float(status_counts['ok']) / float(status_counts['total']))

    return status_counts


class VarnishStatusCollector(Collector):

    def get_default_config(self):
        """
        Returns the default collector settings
        """
        config = super(VarnishStatusCollector, self).get_default_config()
        config.update({
            'path': 'availability',
            'bin':  '/usr/bin/varnishtop',
            'varnishname': None
        })
        return config

    def collect(self):
        """
        Publishes stats to the configured path.
        e.g. /deployment-prep/hostname/availability/#
        with one # for each http status code
        """
        for k, v in get_status_counts(self.config['bin'], self.config['varnishname']).iteritems():
            self.publish_gauge(k, v)


if __name__ == '__main__':
    import datetime
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument('--varnishname', default=None)
    parser.add_argument('--varnishtop', default='/usr/bin/varnishtop')

    args = parser.parse_args()

    status_counts = get_status_counts(varnishtop=args.varnishtop, varnishname=args.varnishname)

    keys = status_counts.keys()
    keys.sort()
    print('\n' + datetime.datetime.now().strftime(' %Y-%m-%dT%H:%M:%S ').center(28, '-'))
    for k in keys:
        print("{0}: {1}".format(k.rjust(12),str(status_counts[k]).rjust(14)))
        if "xx" in k:
            print("")
