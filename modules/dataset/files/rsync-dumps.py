import os
import sys
import re
import subprocess
import socket


class Rsyncer(object):
    def __init__(self, max_bw, dryrun, list_only):
        self.max_bw = str(max_bw)
        self.dryrun = dryrun
        self.list_only = list_only
        self.host = socket.gethostname()
        self.rsync_args = ["--bwlimit=" + self.max_bw, '-a', '--delete']
        if self.list_only:
            self.rsync_args.append("--list-only")
        else:
            self.rsync_args.append("-q")
        self.excludes = ['--exclude=wikidump_*', '--exclude=md5temp.*']

    def get_excludes_for_job(self, jobname, host_info):
        excludes = []
        for job in host_info:
            # 'exclude': { 'dir': 'other', 'job': 'public' }
            if (job != jobname and 'exclude' in host_info[job] and
                    host_info[job]['exclude']['job'] == jobname):
                excludes.append(host_info[job]['exclude']['dir'])
        return excludes

    def rsync_all(self, host_info):
        for job in host_info:
            excludes = self.get_excludes_for_job(job, host_info)

            hosts = host_info[job]['hosts']
            if self.host not in hosts:
                # no rsync job info for this host
                continue

            targets = [h for h in hosts if h != self.host]
            if not len(targets):
                # no hosts to rsync to
                continue

            if 'primary' in hosts[self.host]:
                # this host rsyncs everything except a specific list of dirs
                dir_args = ["--exclude=/" + d.strip('/') + "/" for d in excludes]
                for h in targets:
                    if 'dirs' in hosts[h]:
                        dir_args.extend(["--exclude=/" + d.strip('/') + "/"
                                         for d in hosts[h]['dirs']])

            elif 'dirs' in hosts[self.host]:
                # this host keeps data in a specific list of dirs and must rsync
                # those everywhere else

                dirs_to_include = [d.strip('/') for d in hosts[self.host]['dirs']]
                if not len(dirs_to_include):
                    # no specific dirs to sync
                    continue

                dir_args = ["--include=/" + d + "/" for d in dirs_to_include]
                dir_args.extend(["--include=/" + d + "/**" for d in dirs_to_include])
                dir_args.append('--exclude=*')

            else:
                # not a primary, no specific dirs to sync, do nothing
                continue

            self.do_rsync(host_info[job]['source'], host_info[job]['dest'],
                          targets, dir_args)

    def check_output(self, command):
        process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        output, unused_err = process.communicate()
        retcode = process.poll()
        if retcode:
            raise subprocess.CalledProcessError(retcode, command)
        return output

    def do_rsync(self, src, dest, targets, dir_args):
        for t in targets:
            command = ["/usr/bin/pgrep", "-u", "root", "-f", "%s::%s" % (t, dest)]
            result = subprocess.call(command)
            if result != 1:  # already running or some error
                continue

            command = (["/usr/bin/rsync"] + self.rsync_args + self.excludes +
                       dir_args + [src, "%s::%s" % (t, dest)])
            if self.dryrun:
                print " ".join(command)
            else:
                output = None
                try:
                    output = self.check_output(command)
                except subprocess.CalledProcessError, e:
                    # fixme might want to do something with error output
                    pass
                if output:
                    if self.list_only:
                        print output
                    else:
                        command = ["/usr/bin/mail", '-E', '-s',
                                   "DUMPS RSYNC " + self.host,
                                   'ops-dumps' + '@' + 'wikimedia' + '.org']
                        proc = subprocess.Popen(command, stdin=subprocess.PIPE)
                        (out, errs) = p.communicate(input=output)
                        if errs:
                            print errs  # give up and hope something else sees this


def usage(message):
    if message:
        sys.stderr.write(message + "\n")
        help_message = """Usage: rsync-dumps.py [dryrun] [bw=number] [list]
    dryrun -- show commands that would be run instead of runnning them
    bw     -- cap rsync bandwidth to this number (default: 40000)
    list   -- only list files that would be transferred instead of sending them
"""
        sys.stderr.write(help_message)
        sys.exit(1)

if __name__ == '__main__':
    dryrun = False
    list_only = False
    max_bandwidth = 40000

    for i in range(1, len(sys.argv)):
        if sys.argv[i] == 'dryrun':
            dryrun = True
        elif sys.argv[i].startswith('bw='):
            max_bandwidth = sys.argv[i][3:]
            if not max_bandwidth.isdigit():
                usage("maxbw must be a number")
        elif sys.argv[i] == 'list':
            list_only = True
        else:
            usage("unknown option: " + sys.argv[i])

    r = Rsyncer(max_bandwidth, dryrun, list_only)

    # the rsync commands we would expect to see on...
    # primary for '/public/':
    #   /usr/bin/rsync -v --bwlimit=40000 -a --delete --exclude=wikidump_* --exclude=md5temp.*
    #          --exclude=/dir-done-by-secondary/ --exclude=/another-dir-done-by-secondary/
    #          --exclude=/other/ /data/xmldatadumps/public/ remotehost::data/xmldatadumps/public/
    # secondary for '/public/':
    #   /usr/bin/rsync -v --bwlimit=40000 -a --delete --exclude=wikidump_* --exclude=md5temp.*
    #          --include=/dir-done-by-secondary/ ---include=/another-dir-done-by-secondary/
    #          --include=/dir-done-by-secndary/** --include=/another-dir-done-by-secondary/**
    #          --exclude=* /data/xmldatadumps/public/ remotehost::data/xmldatadumps/public/
    # primary for '/public/other/':
    #   /usr/bin/rsync -v --bwlimit=40000 -a --delete --exclude=wikidump_* --exclude=md5temp.*
    #          --exclude=/subdir-done-by-secondary/ --exclude=/another-subdir-done-by-secondary/
    #          /data/xmldatadumps/public/other/ remotehost::data/xmldatadumps/public/other/
    # secondary for '/public/other/':
    #   /usr/bin/rsync -v --bwlimit=40000 -a --delete --exclude=wikidump_* --exclude=md5temp.*
    #          --include=/subdir-done-by-secondary/ --include=/another-dir-done-by-secondary/
    #          --include=/subdir-done-by-secondary/** --include=/another-subdir-done-by-secondary/**
    #          --exclude=* /data/xmldatadumps/public/other/ remotehost::data/xmldatadumps/public/other/

    host_info = {
        'public': {  # job name
            'source': '/data/xmldatadumps/public/',  # absolute path
            'dest': 'data/xmldatadumps/public/',     # will be prefixed by 'servername::' in rsync
            'hosts': {
                'dataset1001': {'primary': True},    # everything but a specific list of dirs will be pushed
                'dataset2': {'dirs': []}             # only the specified list of dirs is here
            }
        },
        'other': {   # job name
            'exclude': {'dir': 'other', 'job': 'public'},  # don't sync this when doing the 'public' job
            'source': '/data/xmldatadumps/public/other/',
            'dest': 'data/xmldatadumps/public/other/',
            'hosts': {
                'dataset1001': {'dirs': []},
                'dataset2': {'primary': True}
            }
        }
    }
    r.rsync_all(host_info)
