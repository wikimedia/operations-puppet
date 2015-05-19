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


def parse_varnishtop(varnishtop='/usr/bin/varnishtop', varnishname=None):
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

    This method parses that output and returns a list of
    (count, status_code) tuples.
    """

    try:
        command = [varnishtop, "-c", "-i", "TxStatus", "-1"]
        if varnishname:
            command += ["-n", varnishname]

        output = subprocess.check_output(command)

    except Exception as e:
        self.log.error("Error: %s", e)
        output = ""

    # Return a list of (count, status_code) tuples from varnishtop output
    return [
        (int(float(line.split()[0])), line.split()[2]) \
        for line in output.splitlines() if len(line.split()) == 3
    ]


def get_status_counts(varnishtop='/usr/bin/varnishtop', varnishname=None):
    """
    Iterates through the return from parse_varnishtop() and builds a dict with
    request HTTP status counts grouped by by individual HTTP status codes, as well
    as status code classes.  In addition, 'ok' is the number of 2xx + 3xx requests,
    'error' is the number of 4xx + 5xx requests,  'total' is the total number of
    requests, and 'availability' is the percent 'ok' requests served.
    """
    status_counts = {
        '2xx': 0,
        '3xx': 0,
        '4xx': 0,
        '5xx': 0,
        'ok': 0,
        'error': 0,
        'total': 0,
        'availability': 0.0
    }


    for (count, status_code) in parse_varnishtop(varnishtop, varnishname):
        status_class = status_code[:1] + 'xx'

        # Increment total number of requests seen.
        status_counts['total'] += count

        # Increment number of requests with this HTTP status code
        status_counts[status_code] = (
            status_counts.setdefault(status_code, 0) + count
        )

        # Increment number of requests with this HTTP status code class
        status_counts[status_class] = (
            status_counts.setdefault(status_class, 0) + count
            )

    status_counts['ok'] = status_counts['2xx'] + status_counts['3xx']
    status_counts['error'] = status_counts['4xx'] + status_counts['5xx']

    # calculate the percentage of successful out of the total request count
    if status_counts['ok'] > 0 and status_counts['total'] > 0:
        status_counts['availability'] = (
            100 * (float(status_counts['ok']) / float(status_counts['total']))
        )

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
        for k, v in get_status_counts(
            self.config['bin'],
            self.config['varnishname']
        ).iteritems():
            self.publish_gauge(k, v)


if __name__ == '__main__':
    import datetime
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument('--varnishname', default=None)
    parser.add_argument('--varnishtop', default='/usr/bin/varnishtop')

    args = parser.parse_args()

    status_counts = get_status_counts(
        varnishtop=args.varnishtop,
        varnishname=args.varnishname
    )

    # Format and print out status_counts
    keys = status_counts.keys()
    keys.sort()
    print('\n' + datetime.datetime.now().strftime(
        ' %Y-%m-%dT%H:%M:%S ').center(29, '-')
    )
    for k in keys:
        print("{0}: {1}".format(
            k.rjust(12),
            str(status_counts[k]).rjust(15))
        )
        if "xx" in k:
            print("")
