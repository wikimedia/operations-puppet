#!/usr/bin/python
#####################################################################
### THIS FILE IS MANAGED BY PUPPET 
### puppet:///files/powerdns/selective-answer.py
#####################################################################

"""
Selective Answer
A PowerDNS Pipe backend, for selectively answering records to certain participating resolvers.

Copyright (C) 2008 by Mark Bergsma <mark@nedworks.org>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
"""

import sys, stat

ALWAYS, PARTICIPANT, OTHER = range(3)

# Configuration variables
filename = "/etc/powerdns/participants"

dnsRecords = {
'upload.esams.wikimedia.org': [
    # (selectivity, qtype, ttl, content)
    (ALWAYS,      'A',    3600, "91.198.174.234"),
    (PARTICIPANT, 'AAAA', 3600, "2620:0:862:1::80:2"),
    (PARTICIPANT, 'TXT',  3600, "DNS resolver ip %(remoteip)s is listed as a AAAA participant. Please contact ipv6@wikimedia.org if you see any problems."),
    (OTHER,       'TXT',  3600, "DNS resolver ip %(remoteip)s is not listed as a AAAA participant. Please contact ipv6@wikimedia.org if you would like to join in this IPv6 experiment.")
    ]
}


def loadParticipants(filename):
    participants = set()
    try:
        for line in file(filename, 'r'):
            line = line[:-1].strip()
            if len(line) == 0 or line.startswith('#'): continue # Skip empty lines & comments
            ip = line.split('#', 2)[0].strip()                  # Allow comments after the IP
            
            participants.add(ip)
    except:
        print "LOG\tCould not (fully) load participants file", filename
    
    return frozenset(participants)

def answerRecord(qNameSet, (qName, qClass, qType, qId, remoteIp, localIp), participants):
    for record in qNameSet:
        selectivity, rQType, ttl, content = record
        if qType in (rQType, 'ANY', 'AXFR'):
            if (selectivity == ALWAYS
                or (selectivity == PARTICIPANT and remoteIp in participants)
                or (selectivity == OTHER and remoteIp not in participants)):
                
                # Substitute values in the record content
                content = content % {'qname': qName,
                                     'qtype': qType,
                                     'remoteip': remoteIp,
                                     'localip': localIp
                                    }
                print "DATA\t%s\t%s\t%s\t%d\t%d\t%s" % (qName, 'IN', rQType, ttl, int(qId), content)  

def query((qName, qClass, qType, qId, remoteIp, localIp), dnsRecords, participants):
    if qClass == 'IN' and qName.lower() in dnsRecords:
        answerRecord(dnsRecords[qName.lower()], (qName, qClass, qType, qId, remoteIp, localIp), participants)
    print "END"

def axfr(id):
    for qName, qNameSet in dnsRecords.iteritems():
        answerRecord(qNameSet, (qName, "IN", "AXFR", id, "None", "None"), set())
    print "END"

def main():
    participants, lastMTime = set(), 0
    # Do not use buffering
    line = sys.stdin.readline()
    while line:        
        line = line[:-1].strip()
        words = line.split('\t')
        try:
            if words[0] == "HELO":
                if words[1] != "2":
                    print "LOG\tUnknown version", words[1]
                    print "FAIL"
                else:
                    print "OK\tSelective Answer"
            elif words[0] == "Q":
                query(words[1:7], dnsRecords, participants)
            elif words[0] == "AXFR":
                axfr(words[1])
            elif words[0] == "PING":
                pass    # PowerDNS doesn't seem to do anything with this
            else:
                raise ValueError
        except IndexError, ValueError:
            print "LOG\tPowerDNS sent an unparseable line: '%s'" % line
            print "FAIL"    # FAIL!
        
        sys.stdout.flush()
        
        # Reload the participants file if it has changed
        try:
            curMTime = os.stat(filename)[stat.ST_MTIME]
        except OSError:
            pass
        else:
            if curMTime > lastMTime:
                participants = loadParticipants(filename)
                lastMTime = curMTime           
               
        line = sys.stdin.readline()

if __name__ == '__main__':
    # We appear to end up with superfluous FDs, including pipes from other
    # instances, forked from PowerDNS. This can keep us and others from
    # exiting as the fd never gets closed. Close all fds we don't need.
    try:
        import resource
        maxfds = resource.getrlimit(resource.RLIMIT_NOFILE)[1] + 1
        # OS-X reports 9223372036854775808. That's a lot of fds to close
        if maxfds > 1024:
            maxfds = 1024
    except:
        maxfds = 256

    import os
    for fd in range(3, maxfds):
        try: os.close(fd)
        except: pass
    
    main()
