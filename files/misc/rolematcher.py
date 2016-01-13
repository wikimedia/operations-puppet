#!/usr/bin/env python
# -*- coding: utf-8 -*-

'''
This script parses the packet-loss.log file and for each server entry
it determines what it's role is. Server role data has been obtained
from noc.wikimeda.org/pybal and can either be downloaded or the
hard-coded version can be used.

Purpose of this script is to use it in conjunction with
PacketLossLogTailer.py and send packetloss metrics per dc/role to
Ganglia instead of having one overall packetloss metric.

When this script is called directly it runs in testmode,
PacketLossLogTailer.py is the regular point of entry.
'''

import httplib
import re
import urllib2
import json
import sys


numbers = re.compile('([0-9]+)')
base_url = 'http://config-master.wikimedia.org/pybal'
dcs = {
    'eqiad': ['apaches', 'api', 'bits', 'https', 'mobile', 'rendering', 'text', 'upload'],
    'esams': ['bits', 'https', 'text', 'upload'],
}


class RoleMatcher(object):
    def __init__(self, role, regex, start=None, end=None):
        self.role = role
        self.regex = re.compile(regex)
        self.start = start
        self.end = end

    def __str__(self):
        if self.start is not None:
            return '%s:%s-%s' % (self.role, self.start, self.end)
        else:
            return self.role

    def __eq__(self, hostname):
        match = self.regex.match(hostname)
        if match:
            if self.start and self.end:
                try:
                    number = int(match.group(1))
                except IndexError:
                    number = -1
                return self.start <= number and number <= self.end
            else:
                return True
        else:
            return False

    def get_role(self):
        return self.role


def manual_init():
    '''
    This is the hard-coded version of the rolematchers, it's useful for
    testing purposes.
    '''
    matchers = [
        RoleMatcher('eqiad_apache_mw', 'mw([0-9]+)\.eqiad\.wmnet', 1017, 1113),
        RoleMatcher('eqiad_apache_mw', 'mw([0-9]+)\.eqiad\.wmnet', 1161, 1220),
        RoleMatcher('eqiad_api_mw', 'mw([0-9]+)\.eqiad\.wmnet', 1189, 1208),
        RoleMatcher('eqiad_api_mw', 'mw([0-9]+)\.eqiad\.wmnet', 1114, 1148),
        RoleMatcher('eqiad_text_cp', 'cp(10[0-9]+)', 1001, 1020),
        RoleMatcher('eqiad_upload_cp', 'cp(10[0-9]+)', 1021, 1036),
        RoleMatcher('eqiad_mobile_cp', 'cp(104[0-9])+', 1041, 1044),
        RoleMatcher('eqiad_ssl-ip6_ssl', 'ssl(10[0-9])+', 1001, 1004),

        RoleMatcher('esams_bits_cp', 'cp(30[0-9]+)\.esams', 3019, 3022),
        RoleMatcher('esams_upload_cp', 'cp(30[0-9]+)\.esams', 3003, 3010),
        RoleMatcher('esams_ssl-ip6_ssl', 'ssl(300[0-9]+)\.esams', 3001, 3004),
        RoleMatcher('esams_text_kns', 'knsq([0-9]+)\.esams', 23, 30),
        RoleMatcher('esams_upload_knsq', 'knsq([0-9]+)\.esams', 16, 22),
    ]
    return matchers


def parse(data):
    sections = []
    section = []
    for row in data:
        # pybal outputs python dictionaries but we are not going to use eval(),
        # hence make the dictionary JSON compatible.
        row = row.strip().replace('"', '').replace("'", '"').replace('True', 'true').replace('False', 'false')
        if row == '':
            sections.append(section)
            section = []
        elif not row.endswith('}'):  # have to strip out some random comments
            pos = row.find('}')
            row = row[0:pos]
        else:
            if row.startswith('{'):
                try:
                    section.append(json.loads(row))
                except ValueError:
                    pass
    sections.append(section)
    return sections


def determine_server_id(hostname):
    match = re.findall(numbers, hostname)
    try:
        return int(match[0])
    except IndexError:
        return None


def determine_start_end_range(section, hostname):
    if len(section) == 1:
        start = determine_server_id(hostname)
        end = start
    else:
        start = determine_server_id(hostname)
        end = determine_server_id(section[-1]['host'])
    return start, end


def determine_hostname_suffix(hostname):
    suffix = '.'.join(hostname.split('.')[1:])
    suffix = suffix.replace('.', '\\.')
    return suffix


def determine_hostname_prefix(hostname):
    prefix = hostname.split('.')[0]
    prefix = ''.join([i for i in prefix if not i.isdigit()])
    return prefix


def fetch_url(url):
    req = urllib2.Request(url)
    data = []
    try:
        response = urllib2.urlopen(req)
        data = response.readlines()
    except urllib2.HTTPError, e:
        sys.stderr.write('HTTPError = %s' % e.code)
    except urllib2.URLError, e:
        sys.stderr.write('URLError = %s' % e.reason)
    except httplib.HTTPException, e:
        sys.stderr.write('HTTPException')
    except Exception:
        '''
        just to be sure that nothing falls through the cracks
        '''
        import traceback
        sys.stderr.write('Generic exception: %s' % traceback.format_exc())
    return data


def init():
    matchers = []
    elements = {}
    for dc, roles in dcs.iteritems():
        for role in roles:
            url = '/'.join([base_url, dc, role])
            data = fetch_url(url)
            sections = parse(data)
            for section in sections:
                if len(section) > 0:
                    hostname = section[0]['host']
                    start, end = determine_start_end_range(section, hostname)
                    prefix = determine_hostname_prefix(hostname)
                    suffix = determine_hostname_suffix(hostname)
                    if prefix in ['holmium']:
                        if '%s-%s' % (dc, role) not in elements:
                            matcher = RoleMatcher('%s_%s_elements' % (dc, role), 'holmium')
                            elements['%s-%s' % (dc, role)] = True
                            matchers.append(matcher)
                    else:
                        matcher = RoleMatcher('%s_%s_%s' % (dc, role, prefix), '%s([0-9]+)\.%s' % (prefix, suffix), start, end)
                        matchers.append(matcher)
    return matchers


if __name__ == '__main__':
    if len(sys.argv) != 2:
        print 'Please specify path to packetloss log file, call this file only for testing purposes.'
        sys.exit(-1)
    else:
        path = sys.argv[1]

    matchers = init()
    line_matcher = re.compile('^\[(?P<date>[^]]+)\] (?P<server>[^ ]+) lost: \((?P<percentloss>[^ ]+) \+\/- (?P<margin>[^)]+)\)%')
    fh = open(path, 'r')
    for line in fh:
        regMatch = line_matcher.match(line)
        if regMatch:
            fields = regMatch.groupdict()
            hostname = fields['server']
            role = 'misc'  # default group for when we were not able to determine the role
            for matcher in matchers:
                if matcher == hostname:
                    role = matcher.get_role()
                    break
            if hostname == 'total':
                role = 'total'
            print hostname, role
    fh.close()
