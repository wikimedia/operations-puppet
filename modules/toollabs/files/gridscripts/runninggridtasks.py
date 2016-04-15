#!/usr/bin/python
#
# THIS FILE IS MAINTAINED BY PUPPET
# source: modules/toollabs/files/gridscripts/
#
'''
List running tasks on specified hosts.  Output is in yaml; this tool is
generally piped into jobmail.py to notify users of approaching calamity.

Example:

./runningtasks.py tools-exec-1211 tools-exec-1212 tools-exec-1215

'''
from __future__ import print_function
import subprocess
import xml.etree.ElementTree
import itertools
import sys
import yaml

if len(sys.argv) == 1:
    print("Usage: %s hostname [hostname ...]" % sys.argv[0])
    sys.exit(1)


def get_jobs(stream):
    events = xml.etree.ElementTree.iterparse(stream, ['start', 'end'])
    for event, elem in events:
        if event == 'start' and elem.tag == 'host':
            current_host = elem.get('name')
        if event != 'end' or elem.tag != 'job':
            continue
        job = {'host': current_host,
               'id': elem.get('name')}
        for jobvalue in elem.getchildren():
            job[jobvalue.get('name')] = jobvalue.text
        yield job


def groupkey(x):
    return x['job_owner']

proc = subprocess.Popen(
    ['qhost', '-j', '-xml', '-h'] + sys.argv[1:],
    stdout=subprocess.PIPE
)

jobs = [job for job in get_jobs(proc.stdout)
        if not job['queue_name'].startswith('continuous') and
        not job['queue_name'].startswith('webgrid')]

jobs = sorted(jobs, key=lambda x: (groupkey(x), x['start_time']))

data = {owner: list(jobs) for owner, jobs in itertools.groupby(
    jobs, key=groupkey)}
print(yaml.dump(data))
