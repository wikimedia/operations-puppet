#!/usr/bin/python3

import argparse
import logging
import re
import smtplib
import sys

from collections import Counter, defaultdict
from email.message import EmailMessage

import geoip2.database

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger()


def mail(subject, body, to_addr):

    from_addr = 'Fastnetmon <no-reply@wikimedia.org>'

    msg = EmailMessage()
    msg.set_content(body)
    msg['Subject'] = subject
    msg['From'] = from_addr
    msg['To'] = to_addr
    smtp = smtplib.SMTP("localhost")
    smtp.send_message(msg)
    smtp.quit()


def parse_stdin(stdin, geoip_dir=''):

    stdin_clean = []
    errors = ['\nThe following errors happened during the run (if any):']
    netflow_regex = re.compile(r'^.* (?P<src_ip>.*):(?P<src_port>\d+) >'
                               r'\s+(?P<dst_ip>.*):(?P<dst_port>\d+)'
                               r'\s+protocol: (?P<protocol>\w+)'
                               r'\s+(flags: (?P<flags>.*) )?frag: (?P<frag>\d+)'
                               r'\s+packets: \d+ size: (?P<size>\d+) bytes ttl: (?P<ttl>\d+).*')
    netflow_data = defaultdict(Counter)
    netflow_human = []
    total_flows = 0
    try:
        geoip_isp_db = geoip2.database.Reader(geoip_dir + 'GeoIP2-ISP.mmdb')
        geoip_country_db = geoip2.database.Reader(geoip_dir + 'GeoIP2-Country.mmdb')
        geoip = True
    except Exception:
        errors.append('Can\'t load GeoIP database')
        geoip = False
    for line in stdin:
        netflow_raw = netflow_regex.match(line)

        # Ignore useless lines (we only monitor inbound traffic)
        if 'utgoing' in line:  # Some lines have O some o
            continue
        # Parse netflow sample lines
        elif netflow_raw is not None:
            total_flows += 1
            for field, value in netflow_raw.groupdict().items():
                netflow_data[field][value] += 1
                # Do whois (AS/prefix) lookup for src_ip
                if field == 'src_ip' and geoip:
                    try:
                        geoip_isp = geoip_isp_db.isp(value)
                        geoip_country = geoip_country_db.country(value)
                        netflow_data['asn'][geoip_isp.autonomous_system_number] += 1
                        netflow_data['country'][geoip_country.country.iso_code] += 1
                    except Exception as e:
                        errors.append('Can\'t GeoIP lookup {value} - error: {error}'.format(
                            value=value, error=str(e)))
        else:
            stdin_clean.append(line)

    # Once we have the flows properly parsed, we try to find common properties
    netflow_human.append('Only show common properties if shared by at least 1/3 of the '
                         '{total_flows} sample flows exported by FNM.'.format(
                          total_flows=str(total_flows)))
    for field, values in netflow_data.items():
        netflow_human.append(field + ':')
        for value, count in values.most_common(5):
            if count < total_flows/3:
                break
            netflow_human.append('    {value} : {count}'.format(value=str(value), count=str(count)))
    netflow_human.append('\nUse this dashboard for real time data '
                         'and drill-down abilities: https://w.wiki/8oU')
    output = ''.join(stdin_clean) + '\n'.join(netflow_human) + '\n'.join(errors)
    return output


def main():
    arg_parser = argparse.ArgumentParser(description='FastNetMon notify')
    arg_parser.add_argument('--email', help='Send email')
    arg_parser.add_argument('--geoip', help='GeoIP binaries folder', default='')
    arg_parser.add_argument('target', help='Target')
    arg_parser.add_argument('direction', help='Traffic direction')
    arg_parser.add_argument('pps', help='Packets per seconds')
    arg_parser.add_argument('action', help='ban=start, unban=end, \
                            attack_details=start with more info',
                            choices=['ban', 'unban', 'attack_details'])

    args = arg_parser.parse_args()
    event_short = 'Possible DDoS to {target} ({pps}pps)'.format(target=args.target, pps=args.pps)

    if args.action in ['ban', 'attack_details']:
        logger.info('START: {event_short}'.format(event_short=event_short))
        extra_data = parse_stdin(sys.stdin.readlines(), args.geoip)
        if args.email:
            mail(event_short, extra_data, args.email)
        else:
            logger.info(extra_data)

    if args.action == 'unban':
        logger.info('END: {event_short}'.format(event_short=event_short))
        if args.email:
            mail(event_short)


if __name__ == '__main__':
    main()
