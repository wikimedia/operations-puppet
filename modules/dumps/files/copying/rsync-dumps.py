import getopt
import sys
import subprocess
import socket
############################
# This file is managed by puppet!
# puppet:///modules/dumps/copying/rsync-dumps.py
###########################


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

    def rsync_all(self, rsync_info):
        for job in rsync_info:
            excludes = self.get_excludes_for_job(job, rsync_info)

            hosts = rsync_info[job]['hosts']
            if self.host not in hosts:
                # no rsync job info for this host
                continue

            targets = [h for h in hosts if h != self.host]
            if not len(targets):
                # no hosts to rsync to
                continue

            if 'primary' in hosts[self.host]:
                # this host rsyncs everything except a specific list of dirs
                dir_args = ["--exclude=/" + d.strip('/') + "/"
                            for d in excludes]
                for targ in targets:
                    if 'dirs' in hosts[targ]:
                        dir_args.extend(["--exclude=/" + d.strip('/') + "/"
                                         for d in hosts[targ]['dirs']])

            elif 'dirs' in hosts[self.host]:
                # this host keeps data in a specific list of dirs and must
                # rsync those everywhere else

                dirs_to_include = [d.strip('/')
                                   for d in hosts[self.host]['dirs']]
                if not len(dirs_to_include):
                    # no specific dirs to sync
                    continue

                dir_args = ["--include=/" + d + "/" for d in dirs_to_include]
                dir_args.extend(["--include=/" + d + "/**"
                                 for d in dirs_to_include])
                dir_args.append('--exclude=*')

            else:
                # not a primary, no specific dirs to sync, do nothing
                continue

            self.do_rsync(rsync_info[job]['source'], rsync_info[job]['dest'],
                          targets, dir_args)

    def do_rsync(self, src, dest, targets, dir_args):
        for targ in targets:
            command = ["/usr/bin/pgrep", "-u", "root",
                       "-f", "%s::%s" % (targ, dest)]
            try:
                subprocess.check_output(command)
                # return code 0 = already running
                if self.dryrun:
                    print "would skip rsync to", "%s::%s" % (targ, dest)
                continue
            except subprocess.CalledProcessError as err:
                if err.returncode != 1:
                    # genuine error
                    raise

            command = (["/usr/bin/rsync"] + self.rsync_args + self.excludes +
                       dir_args + [src, "%s::%s" % (targ, dest)])
            if self.dryrun:
                print "would run", " ".join(command)
            else:
                output = None
                try:
                    output = subprocess.check_output(command)
                except subprocess.CalledProcessError:
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
                        (out_unused, errs) = proc.communicate(input=output)
                        if errs:
                            # give up and hope something else sees this
                            print errs


def get_rsync_info_default():
    # The rsync commands we would expect to see on...
    #
    # Primary for '/public/':
    #   /usr/bin/rsync -v --bwlimit=40000 -a --delete
    #          --exclude=wikidump_* --exclude=md5temp.*
    #          --exclude=/dir-done-by-secondary/
    #          --exclude=/another-dir-done-by-secondary/
    #          --exclude=/other/
    #          /data/xmldatadumps/public/
    #          remotehost::data/xmldatadumps/public/
    #
    # Secondary for '/public/':
    #   /usr/bin/rsync -v --bwlimit=40000 -a --delete
    #          --exclude=wikidump_* --exclude=md5temp.*
    #          --include=/dir-done-by-secondary/
    #          --include=/another-dir-done-by-secondary/
    #          --include=/dir-done-by-secndary/**
    #          --include=/another-dir-done-by-secondary/**
    #          --exclude=*
    #          /data/xmldatadumps/public/
    #          remotehost::data/xmldatadumps/public/
    #
    # primary for '/public/other/':
    #   /usr/bin/rsync -v --bwlimit=40000 -a --delete
    #          --exclude=wikidump_* --exclude=md5temp.*
    #          --exclude=/subdir-done-by-secondary/
    #          --exclude=/another-subdir-done-by-secondary/
    #          /data/xmldatadumps/public/other/
    #          remotehost::data/xmldatadumps/public/other/
    #
    # secondary for '/public/other/':
    #   /usr/bin/rsync -v --bwlimit=40000 -a --delete
    #          --exclude=wikidump_* --exclude=md5temp.*
    #          --include=/subdir-done-by-secondary/
    #          --include=/another-dir-done-by-secondary/
    #          --include=/subdir-done-by-secondary/**
    #          --include=/another-subdir-done-by-secondary/**
    #          --exclude=*
    #          /data/xmldatadumps/public/other/
    #          remotehost::data/xmldatadumps/public/other/

    rsync_info = {
        'public': {  # job name
            # source is an absolute path
            'source': '/data/xmldatadumps/public/',
            # dest will be prefixed by 'servername::' in rsync
            'dest': 'data/xmldatadumps/public/',
            'hosts': {}
        },
        'other': {   # job name
            # don't sync this when doing the 'public' job:
            'exclude': {'dir': 'other', 'job': 'public'},

            'source': '/data/xmldatadumps/public/other/',
            'dest': 'data/xmldatadumps/public/other/',
            'hosts': {}
        }
    }
    return rsync_info


def get_source_info(servers, sources_known):
    """
    convert servers string argument into a nice structure
    containing: source, server, is it primary or secondary,
    and if it is secondary, a list of directorys which it manages
    """
    sources = {}
    # source=name,server=name,type=primary,dirs=a:b:c; \
    #     source=name,server=name,type=secondary,dirs=a:b:c;...
    source_entries = servers.split(';')
    for source_entry in source_entries:
        source_info = {}
        args = source_entry.split(',')
        for arg in args:
            if '=' not in arg:
                usage("bad server info supplied: %s (bad arg %s)" % (servers, arg))
            name, value = arg.split('=')
            if name == 'source':
                if value not in sources_known:
                    usage("bad server info supplied: %s (bad source name %s)" % (servers, value))
                source_info['source'] = value
            elif name == 'server':
                source_info['server'] = value
            elif name == 'type':
                if value not in ['primary', 'secondary']:
                    usage("bad server info supplied: %s (bad type %s)" % (servers, value))
                source_info['type'] = value
            elif name == 'dirs':
                source_info['dirs'] = value.split(':')
            else:
                usage("bad server info supplied: %s (bad arg name %s)" % (servers, name))
        if 'source' not in source_info or 'server' not in source_info or 'type' not in source_info:
            usage("bad server info supplied: %s (missing source, server or type name)" % servers)
        if source_info['type'] == 'secondary' and 'dirs' not in source_info:
            source_info['dirs'] = []
        if source_info['source'] not in sources:
            sources[source_info['source']] = []
        sources[source_info['source']].append(source_info)
    return sources


def rsync_info_update(rsync_info, sources_info):
    for source in rsync_info:
        for entry in sources_info[source]:
            # Note that if a source has multiple entries for a server, the
            # last entry will override earlier ones. You probably just want
            # to avoid dups.
            if entry['type'] == 'primary':
                rsync_info[source]['hosts'][entry['server']] = {'primary': True}
            elif entry['type'] == 'secondary':
                rsync_info[source]['hosts'][entry['server']] = {'dirs': entry['dirs']}
    return rsync_info


def usage(message):
    if message:
        sys.stderr.write(message + "\n")
        help_message = """Usage: rsync-dumps.py servers <serverlist>
                     [--dryrun] [--bandwidth <number>] [--list]

Arguments:
    servers    (-s) -- list of servers and their directories associated with each source
                       Format:  source=name,server=name,type=primary; \
                                source=name,server=name,type=secondary,dirs=a:b:c;...
                         source: one of the sources listed in this script (currently 'public' or 'other').
                                default: none
                         server: short name of server, fqdn not needed.  default: none
                         type: primary (all dirs will be rsynced to peer except those hosted by the secondary)
                               secondary (only listed dirs will be rsynced). default: none
                         dirs: list of directories for rsync, if server is secondary. default: empty list
    bandwidth  (-b) -- cap rsync bandwidth to this number (default: 40000)

Flags:
    list       (-l) -- only list files that would be transferred instead of sending them
    dryrun     (-d) -- show commands that would be run instead of runnning them
    help       (-h) -- show this message
"""
        sys.stderr.write(help_message)
        sys.exit(1)


def do_main():
    dryrun = False
    list_only = False
    max_bandwidth = 40000
    servers = None

    try:
        (options, remainder) = getopt.gnu_getopt(
            sys.argv[1:], "b:s:ldh",
            ["bandwidth=", "servers=", "list", "dryrun", "help"])

    except getopt.GetoptError as err:
        usage("Unknown option specified: " + str(err))
    for (opt, val) in options:
        if opt in ["-b", "--bandwidth"]:
            max_bandwidth = val
            if not max_bandwidth.isdigit():
                usage("maxbw must be a number")
        elif opt in ["-s", "--servers"]:
            servers = val
        elif opt in ["-l", "--list"]:
            list_only = True
        elif opt in ["-d", "--dryrun"]:
            dryrun = True
        elif opt in ["-h", "--help"]:
            usage('Help for this script\n')
        else:
            usage("Unknown option specified: <%s>" % opt)

    if servers is None:
        usage("Mandatory 'servers' argument omitted")

    rsync = Rsyncer(max_bandwidth, dryrun, list_only)
    rsync_info = get_rsync_info_default()
    source_info = get_source_info(servers, rsync_info.keys())
    errors = False
    for source in rsync_info:
        if source not in source_info:
            sys.stderr.write("no servers specified for source %s\n" % source)
            errors = True
    if errors:
        sys.exit(1)

    rsync_info_update(rsync_info, source_info)

    rsync.rsync_all(rsync_info)


if __name__ == '__main__':
    do_main()
