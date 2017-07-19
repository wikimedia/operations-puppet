import getopt
import json
import os
import sys
import subprocess
from subprocess import Popen, PIPE
import ConfigParser


"""
rsync completed xml dump jobs to target host/dir

we don't rsync incomplete files because we'll just end up
copying large partial files on every run and wasting bandwith
for the big wiki dumps (e.g. enwiki)

later we need to deal with rsync of the files in other/ etc, ugh

"""


class Rsyncer(object):
    def __init__(self, rsync_args, configfile, dryrun, list_only):
        self.rsync_args = rsync_args
        self.dryrun = dryrun
        self.configfile = configfile
        self.list_only = list_only

    def get_wikis_to_rsync(self):
        conf = ConfigParser.SafeConfigParser()
        conf.read(self.configfile)
        list_of_wikis = conf.get("wiki", "dblist")
        with open(list_of_wikis) as fhandle:
            wikis = []
            for line in fhandle:
                line = line.strip()
                if line != "":
                    wikis.append(line)
            fhandle.close()
        return sorted(wikis)

    def get_dumpstatus(self, dirname):
        statusfile = os.path.join(dirname, "dumpstatus.json")
        status = None
        try:
            with open(statusfile) as fhandle:
                contents = fhandle.read()
                status = json.loads(contents)
                fhandle.close()
            return status
        except Exception:
            return None

    def get_specialfiles(self, dirname):
        infofile = os.path.join(dirname, "dumpspecialfiles.json")
        specials = None
        try:
            with open(infofile) as fhandle:
                contents = fhandle.read()
                specials = json.loads(contents)
                fhandle.close()
            return specials
        except Exception:
            return None

    def get_files_to_rsync_in_dir(self, dirname):
        dumpstatus = self.get_dumpstatus(dirname)
        files = []
        if not dumpstatus:
            return files
        try:
            for job in dumpstatus['jobs']:
                if dumpstatus['jobs'][job]['status'] != 'done':
                    next
                    files.extend(dumpstatus['jobs'][job]['files'].keys())
        except Exception:
            pass
        return [os.path.join(dirname, filename) for filename in files]

    def get_special_files_to_rsync_in_dir(self, dirname):
        specialfiles = self.get_specialfiles(dirname)
        files = []
        if not specialfiles:
            return files
        try:
            for filename in specialfiles['files']:
                if specialfiles['files'][filename]['status'] != 'present':
                    next
                files.extend(filename)
        except Exception:
            pass
        return [os.path.join(dirname, filename) for filename in files]

    def get_directories(self, wiki):
        # fixme write this
        pass

    def get_files_to_rsync(self, wiki):
        dirs = self.get_directories(wiki)
        files = []
        for dirname in dirs:
            files.extend(self.get_files_to_rsync_in_dir(dirname))
        # claim is that sorting these makes rsync more efficient when it goes to sync them
        return sorted(files)

    def get_special_files_to_rsync(self, wiki):
        dirs = self.get_directories(wiki)
        files = []
        for dirname in dirs:
            files.extend(self.get_special_files_to_rsync_in_dir(dirname))
        # claim is that sorting these makes rsync more efficient when it goes to sync them
        return sorted(files)

    def rsync_files(self, wiki, files):
        command = ["/usr/bin/rsync"]
        command.append("--files-from=-")
        command.extend(self.rsync_args)
        process = Popen(command, stdin=PIPE, stdout=PIPE, stderr=PIPE, shell=False)
        # FIXME there's this issue with the full path and etc.
        output, errors = process.communicate(input=" ".join(files))

    def get_toplevel_files(self):
        files = []
        # get index.htmls, rsync file listings
        # FIXME write this
        return files

    def already_running():
        command = ["/usr/bin/pgrep", "-f", "rsync_completed_dumpjobs.py"]
        try:
            subprocess.check_output(command)
            # return code 0 = already running, anything else excepts
            return False
        except subprocess.CalledProcessError as err:
            if err.returncode != 1:
                # genuine error
                raise
            else:
                return True

    def rsync(self):
        if self.already_running():
            return
        wikis = self.get_wikis_to_rsync()
        for wiki in wikis:
            files = self.get_files_to_rsync(wiki)
            self.rsync_files(wiki, files)
            files = self.get_special_files_to_rsync(wiki)
            self.rsync_files(wiki, files)
        files = self.get_toplevel_files()
        self.rsync_files(None, files)


def usage(message=None):
    '''
    display a helpful usage message with
    an optional introductory message first
    '''

    if message is not None:
        sys.stderr.write(message)
        sys.stderr.write("\n")
    usage_message = """
Usage: rsync_completed_dumpjobs.py --configfile <path> [--rsyncargs <args>]
                  [--dryrun] [--listonly]| --help

Options:
  --configfile  (-c):  path to confguration file for dumps
  --rsyncargs   (-r):  additional arguments to be passed to rsync
  --listonly    (-l):  list files that would be transferred, don't actually
                       transfer them
  --dryrun      (-d):  don't rsync, show the commands that would be run
  --help        (-h):  display this help message
"""
    sys.stderr.write(usage_message)
    sys.exit(1)


def validate_args(configfile, remainder):
    if configfile is None:
        usage("Mandatory configfile argument is missing")
    elif len(remainder) > 0:
        usage("Unknown option(s) specified: <%s>" % remainder[0])


def process_args():
    """
    get and check validity of command line args
    """
    dryrun = False
    list_only = False
    rsync_args = []
    configfile = None
    try:
        (options, remainder) = getopt.gnu_getopt(
            sys.argv[1:], "c:r:l:dh", ["confilefile=", "rsyncargs=", "listonly", "dryrun", "help"])
    except getopt.GetoptError as err:
        usage("Unknown option specified: " + str(err))

    for (opt, val) in options:
        if opt in ["-c", "--configfile"]:
            configfile = val
        elif opt in ["-r", "--rsyncargs"]:
            rsync_args = val.split(',')
        elif opt in ["-l", "--listonly"]:
            list_only = True
        elif opt in ["-d", "--dryrun"]:
            dryrun = True
        elif opt in ["-h", "--help"]:
            usage("Help for this script")

    validate_args(configfile, remainder)
    return dryrun, list_only, rsync_args, configfile


def do_main():
    dryrun, list_only, rsync_args, configfile = process_args()
    rsyncer = Rsyncer(rsync_args, configfile, dryrun, list_only)
    rsyncer.rsync()

    # Primary for '/public/':
    #   /usr/bin/rsync -v --bwlimit=40000 -a --delete
    #          --exclude=wikidump_* --exclude=md5temp.*
    #          --exclude=/dir-done-by-secondary/
    #          --exclude=/another-dir-done-by-secondary/
    #          --exclude=/other/
    #          /data/xmldatadumps/public/
    #          remotehost::data/xmldatadumps/public/
    #


if __name__ == '__main__':
    do_main()
