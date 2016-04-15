#!/usr/bin/python
#
# THIS FILE IS MAINTAINED BY PUPPET
# source: modules/toollabs/files/gridscripts/
#
'''
Takes the yaml output of runningtasks.py and emails respective tool
owners about doomed jobs.

Example:

./runningtasks.py tools-exec-1211 tools-exec-1212 tools-exec-1215 | jobmail.py

'''
import yaml
import subprocess

with open("jobs.yaml", 'r') as stream:
    tools = yaml.load(stream)

    for tool in tools.keys():
        joblist = []
        jobs = tools[tool]
        for job in jobs:
            joblist.append(job['job_name'])

        msg = """Hello!

    Due to an upcoming server reboot, the following jobs will be killed
tomorrow at 15:00 UTC:

%s

   These jobs will not be automatically restarted. If you restart the jobs
manually before the upcoming reboot, they will restart on a different host
which limits the downtime.

    Be warned that you may receive another one of these messages in the
next few days for the same jobs.  This is not in error -- each server
needs rebooting, and as a result you may have to reschedule more than
once.
    For more information, visit
https://wikitech.wikimedia.org/wiki/Virt_node_upgrade_schedule

    Thank you, and sorry for the inconvenience.

- your friendly labs admins""" % "\n".join(joblist)

        victim = "%s@tools.wmflabs.org" % tool
        print victim

        p = subprocess.Popen(['mail', '-r', 'abogott@wikimedia.org', '-s',
                              'Please restart your toollabs jobs',
                              victim], stdin=subprocess.PIPE)
        p.stdin.write(msg)
        p.communicate()[0]
        p.stdin.close()
