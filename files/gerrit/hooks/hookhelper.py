#!/usr/bin/python
import sys
import re
import paramiko
import socket
import json
import traceback

from optparse import OptionParser

sys.path.append('/var/lib/gerrit2/review_site/etc')
import hookconfig


class HookHelper:
    def __init__(self):
        self.patchsets = {}
        self.parser = OptionParser(conflict_handler="resolve")
        self.add_default_options()

    def add_default_options(self):
        self.parser.add_option("--change", dest="change")
        self.parser.add_option("--change-url", dest="changeurl")
        self.parser.add_option("--project", dest="project")
        self.parser.add_option("--branch", dest="branch")

    def ssh_exec_command(self, command):
        ssh = paramiko.SSHClient()
        ssh.load_host_keys(hookconfig.sshhostkeys)
        try:
            ssh.connect(hookconfig.sshhost,
                        hookconfig.sshport, hookconfig.gerrituser,
                        key_filename=hookconfig.sshkey)
            stdin, stdout, stderr = ssh.exec_command(command)
            out = stdout.readlines()
            err = stderr.readlines()
            ssh.close()
            return (out, err)
        except (paramiko.SSHException, socket.error):
            sys.stderr.write("Failed to connect to %s." % hookconfig.sshhost)
            traceback.print_exc(file=sys.stderr)
            return (None, None)

    def get_patchsets(self, change):
        command = 'gerrit query --format=JSON --patch-sets ' + change
        queryresult, err = self.ssh_exec_command(command)
        if not queryresult:
            sys.stderr.write("Couldn't find patchset for change: " +
                             change + "\n")
            return False
        try:
            self.patchsets[change] = json.loads(queryresult[0])
            return True
        except Exception:
            sys.stderr.write("Couldn't load patchset json for change: " +
                             change + "\n")
            traceback.print_exc(file=sys.stderr)
            return False

    def get_subject(self, change):
        if change not in self.patchsets:
            patchsets_fetched = self.get_patchsets(change)
            if not patchsets_fetched:
                return None
        if "subject" in self.patchsets[change].keys():
            subject = str(self.patchsets[change]['subject'])
            if not subject:
                subject = "(no subject)"
        else:
            subject = "(no subject)"
        return subject

    def log_to_file(self, project, branch, message, user):
        filename = self.get_log_filename(project, branch, message)
        # These users are REALLY annoying, ignore them
        if user in hookconfig.reallyspammyusers:
            return
        f = open(filename, 'a')
        f.write(message)
        f.close()

    def get_log_filename(self, project, branch, message):
        filename = None
        foundproject = None
        if hookconfig.logdir and hookconfig.logdir[-1] == '/':
            hookconfig.logdir = hookconfig.logdir[0:-1]
        if project in hookconfig.filenames:
            foundproject = project
        if foundproject is None:
            # Attempt to use the wildcard filters
            for filter, value in hookconfig.filenames.iteritems():
                if not "*" in filter:
                    # It is a project name, not a filter!
                    continue
                # Replace wildcard with a proper regex snippet
                pattern = re.compile(filter.replace('*', '.+'))
                if(pattern.match(project)):
                    foundproject = filter
                    break
        if foundproject is None:
            foundproject = 'default'
        if branch not in hookconfig.filenames[foundproject]:
            branch = 'default'
        if branch in hookconfig.filenames[foundproject]:
            filename = hookconfig.filenames[foundproject][branch]
        else:
            # Direct assignement such as 'default': 'wikimedia-dev.log'
            filename = hookconfig.filenames[foundproject]
        return hookconfig.logdir + "/" + filename
