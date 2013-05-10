# -*- coding: utf-8 -*-
#!/usr/bin/env python

'''
This script parses the packet-loss.log file and for each server entry
it determines what it's role is. Server role data has been obtained 
from noc.wikimeda.org/pybal and is currently hardcoded.

Purpose of this script is to use it in conjunction with 
PacketLossLogTailer.py and send packetloss metrics per dc/role to 
Ganglia instead of having one overall packetloss metric. 

When this script is called directly it runs in testmode, 
PacketLossLogTailer.py is the regular point of entry.
'''

import re

numbers = re.compile('[0-9]{1-4}')

class RoleMatcher(object):
    def __init__(self, role, regex, start=None, end=None):
        self.role = role
        self.regex= re.compile(regex)
        self.start = start
        self.end = end
    
    def __str__(self):
        if self.start != None:
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
        return self.__str__()

def init():
    matchers = [
        RoleMatcher('pmtpa_apache_mw', 'mw([0-9]+)\.pmtpa\.wmnet', 226, 249),
        RoleMatcher('pmtpa_apache_mw', 'mw([0-9]+)\.pmtpa\.wmnet', 258, 289),
        RoleMatcher('pmtpa_apache_mw', 'mw([0-9]+)\.pmtpa\.wmnet', 17, 59),
        RoleMatcher('pmtpa_apache_mw', 'mw([0-9]+)\.pmtpa\.wmnet', 81, 111),
        RoleMatcher('pmtpa_rendering_mw', 'mw([0-9]+)\.pmtpa\.wmnet', 75, 80),
        RoleMatcher('pmtpa_api_mw', 'mw([0-9]+)\.pmtpa\.wmnet', 250, 257),
        RoleMatcher('pmtpa_api_mw', 'mw([0-9]+)\.pmtpa\.wmnet', 290, 301),
        RoleMatcher('pmtpa_api_mw', 'mw([0-9]+)\.pmtpa\.wmnet', 62, 74),
        RoleMatcher('pmtpa_api_mw', 'mw([0-9]+)\.pmtpa\.wmnet', 112, 125),
        RoleMatcher('pmtpa_bits_sq', 'sq([0-9]+)\.pmtpa\.wmnet', 67, 70),
        RoleMatcher('pmtpa_text_sq', 'sq([0-9]+)\.pmtpa\.wmnet', 37, 37),
        RoleMatcher('pmtpa_text_sq', 'sq([0-9]+)\.pmtpa\.wmnet', 59, 66),
        RoleMatcher('pmtpa_text_sq', 'sq([0-9]+)\.pmtpa\.wmnet', 71, 78),
        RoleMatcher('pmtpa_ssl-ip6_ssl', 'ssl([0-9]{1})', 1, 4),
        RoleMatcher('pmtpa_mobile_mobile', 'mobile([0-9]{1})', 1, 4),
        RoleMatcher('pmtpa_upload_sq', 'sq([0-9]+)', 41, 58),
        RoleMatcher('pmtpa_upload_sq', 'sq([0-9]+)', 79, 86),

        RoleMatcher('eqiad_apache_mw', 'mw([0-9]+)\.eqiad\.wmnet', 1017, 1113),
        RoleMatcher('eqiad_apache_mw', 'mw([0-9]+)\.eqiad\.wmnet', 1161, 1220),
        RoleMatcher('eqiad_api_mw', 'mw([0-9]+)\.eqiad\.wmnet', 1189, 1208),
        RoleMatcher('eqiad_api_mw', 'mw([0-9]+)\.eqiad\.wmnet', 1114, 1148),
        RoleMatcher('eqiad_text_cp', 'cp(10[0-9]+)', 1001, 1020),
        RoleMatcher('eqiad_upload_cp', 'cp(10[0-9]+)', 1021, 1036),
        RoleMatcher('eqiad_mobile_cp', 'cp(104[0-9])+', 1041, 1044),
        RoleMatcher('eqiad_bits', '(arsenic|strontium|niobum|palladium|dysprosium)'),
        RoleMatcher('eqiad_ssl-ip6_ssl', 'ssl(10[0-9])+', 1001, 1004),

        RoleMatcher('esams_bits_cp', 'cp(30[0-9]+)\.esams', 3019, 3022),
        RoleMatcher('esams_upload_cp', 'cp(30[0-9]+)\.esams', 3003, 3010),
        RoleMatcher('esams_ssl-ip6_ssl', 'ssl(300[0-9]+)\.esams', 3001, 3004),
        RoleMatcher('esams_text_kns', 'knsq([0-9]+)\.esams', 23, 30),
        RoleMatcher('esams_text_amssq', 'amssq([0-9]+)\.esams', 31, 46),
        RoleMatcher('esams_upload_knsq', 'knsq([0-9]+)\.esams', 16, 22),
        RoleMatcher('esams_upload_amssq', 'amssq([0-9]+)\.esams', 47, 62),
    ]
    return matchers

if __name__ == '__main__':
    line_matcher = re.compile ('^\[(?P<date>[^]]+)\] (?P<server>[^ ]+) lost: \((?P<percentloss>[^ ]+) \+\/- (?P<margin>[^)]+)\)%')
    fh = open('/Users/diederik/Downloads/packet-loss.log-20130510', 'r')
    matchers = init()
    
    for line in fh:
        regMatch = line_matcher.match(line)
        if regMatch:
            fields = regMatch.groupdict()
            hostname = fields['server']
            role = 'misc' # default group for when we were not able to determine the role
            for matcher in matchers:
                if matcher == hostname: 
                    role = matcher.get_role()
                    break;
            if hostname == 'total':
                role = 'total'
            print hostname, role
    fh.close()
            





