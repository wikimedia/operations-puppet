"""
rsync completed xml dump jobs to target host/dir

we don't rsync incomplete files because we'll just end up
copying large partial files on every run and wasting bandwith
for the big wiki dumps (e.g. enwiki)
"""

# todo
# make dest be an arg and take multiple rsync dests with comma sep
#   and do the copy of each group of files to each host in turn
#   (what happens if one host is consistently down? ummm)
# make sure I have the wiki and datestring in there in the rsync destination
#   the metadata files, some don't have the wiki name and date, so when we
# copy them into temp dir for all the date runs we have lying around,
#   it's going to be a problem.


import getopt
import glob
import json
import os
import os.path
import sys
import shutil
import subprocess
from subprocess import Popen, PIPE


def get_dumpstatus(dirname):
    """
    read and return dump status information from file
    """
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


def get_metadata_files(dirname):
    """
    read and return dict of dump metadata files with info about each
    """
    infofile = os.path.join(dirname, "dumpspecialfiles.json")
    metadata_files = None
    try:
        with open(infofile) as fhandle:
            contents = fhandle.read()
            metadata_files = json.loads(contents)
            fhandle.close()
        return metadata_files
    except Exception:
        return None


def get_files_to_rsync_in_dir(dirname):
    """
    given a dict of dump output files plus info about each,
    return a list of only the ones with status 'done'
    (which means they have been completely written out and closed)
    """
    dumpstatus = get_dumpstatus(dirname)
    files = []
    if not dumpstatus:
        return files
    try:
        for job in dumpstatus['jobs']:
            if dumpstatus['jobs'][job]['status'] != 'done':
                continue
            files.extend(dumpstatus['jobs'][job]['files'].keys())
    except Exception:
        pass
    return [os.path.join(dirname, filename) for filename in files]


def get_metadata_files_to_rsync_in_dir(dirname):
    metadata_files = get_metadata_files(dirname)
    files = []
    if not metadata_files:
        return files
    try:
        for filename in metadata_files['files']:
            if metadata_files['files'][filename]['status'] != 'present':
                continue
            files.extend(filename)
    except Exception:
        pass
    return [os.path.join(dirname, filename) for filename in files]


def get_directories(wikidir):
    """
    return all full paths of names in the given directory that look like YYYYMMDD
    or the 'latest' dir (has symlinks to latest versions of each dump file)

    we don't filter to make sure they are directories, we just assume.
    """
    return [os.path.join(wikidir, dirname) for dirname in os.listdir(wikidir)
            if (dirname.isdigit() and len(dirname) == 8 and dirname.startswith("2")) or
            dirname == "latest"]


def get_files_to_rsync(wikidir):
    """
    return full paths of completed dump output files for the specific wiki
    in all subdirectories
    """
    dirs = get_directories(wikidir)
    files = []
    for dirname in dirs:
        files.extend(get_files_to_rsync_in_dir(os.path.join(wikidir, dirname)))
    # claim is that sorting these makes rsync more efficient when it goes to sync them
    return sorted(files)


def get_metadata_files_to_rsync(wikidir):
    """
    return full paths of dump metadata files for the specific wiki
    in all subdirectories
    """
    dirs = get_directories(wikidir)
    files = []
    for dirname in dirs:
        files.extend(get_metadata_files_to_rsync_in_dir(os.path.join(wikidir, dirname)))
    # claim is that sorting these makes rsync more efficient when it goes to sync them
    return sorted(files)


def already_running():
    """
    check to see if a process of this name is already running
    if so, return True, otherwise return False
    """
    command = ["/usr/bin/pgrep", "-f", "copy_completed_dumpfiles.py"]
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


class Rsyncer(object):
    """
    methods for rsyncing a consistent copy of dump output data:

    make a temporary copy of metadata files
    rsync dump output files to remote destination
    rsync dump metadata files to remote destination
    delete extraneous files from remote destination via rsync
    """
    def __init__(self, rsync_args, basedir, dryrun, verbose, list_only):
        self.rsync_args = rsync_args
        self.basedir = basedir
        self.dryrun = dryrun
        self.verbose = verbose
        self.list_only = list_only
        self.tempdir = os.path.join(basedir, "tmp")

    def get_wikis_to_rsync(self):
        wikis = [wiki for wiki in os.listdir(self.basedir) if wiki != "tmp"]
        return sorted(wikis)

    def rsync_files(self, wiki, files):
        command = ["/usr/bin/rsync"]
        command.append("--files-from=-")
        command.extend(self.rsync_args)
        if self.list_only:
            command.append("--list-only")
        process = Popen(command, stdin=PIPE, stdout=PIPE, stderr=PIPE, shell=False)
        output, errors = process.communicate(input=" ".join(files))
        if self.verbose and output:
            print output
        if process.returncode:
            sys.stderr.write("error encountered rsyncing {wiki}\n".format(wiki=wiki))
        if errors:
            sys.stderr.write(errors)
        return process.returncode

    def delete_remote_junk(self, wiki):
        """
        for a given wiki and date, delete the files on the remote side that
        don't exist on the local side, using rsync
        """
        command = ["/usr/bin/rsync", "-lpt"]
        command.extend(["--existing", "--ignore-existing", "--delete-after"])
        command.extend(self.rsync_args)
        if self.list_only:
            command.append("--list-only")
        process = Popen(command, stdin=PIPE, stdout=PIPE, stderr=PIPE, shell=False)
        output, errors = process.communicate(input="")
        if self.verbose and output:
            print output
        if process.returncode:
            sys.stderr.write("error encountered cleaning "
                             "up {wiki} on remote host\n".format(wiki=wiki))
        if errors:
            sys.stderr.write(errors)
        return process.returncode

    def delete_tempsaved(self, filenames=None):
        """
        remove files from tempdir
        """
        errors = 0
        if not filenames:
            filenames = os.listdir(self.tempdir)

        for filename in filenames:
            try:
                os.unlink(os.path.join(self.tempdir, filename))
            except Exception:
                errors = 1
        return errors

    def tempsave(self, wiki, metadata_files):
        """
        make a copy of each dumps metadata file in a temp dir
        so we can rsync these later, after files they may refer
        to have all been copied
        """
        for path in metadata_files:
            shutil.copy2(path, self.tempdir)

    def get_toplevel_html_files(self):
        return glob.glob(os.path.join(self.basedir, '*.html'))

    def rsync(self):
        if already_running():
            return
        top_htmls = self.get_toplevel_html_files()
        self.tempsave(None, top_htmls)
        wikis = self.get_wikis_to_rsync()
        errors = 0
        for wiki in wikis:
            metadata_files = get_metadata_files_to_rsync(os.path.join(self.basedir, wiki))
            regular_files = get_files_to_rsync(os.path.join(self.basedir, wiki))
            self.tempsave(wiki, metadata_files)
            errors += self.rsync_files(wiki, regular_files)
            errors += self.rsync_files(wiki, metadata_files)
            errors += self.delete_remote_junk(wiki)
            self.delete_tempsaved([os.path.basename(path) for path in metadata_files])
        errors += self.rsync_files(None, top_htmls)
        self.delete_tempsaved(top_htmls)

        self.delete_tempsaved()
        return errors


def usage(message=None):
    '''
    display a helpful usage message with
    an optional introductory message first
    '''

    if message is not None:
        sys.stderr.write(message)
        sys.stderr.write("\n")
    usage_message = """
Usage: rsync_completed_dumpjobs.py --basedir <path> [--rsyncargs <args>]
                  [--dryrun] [--verbose] [--listonly]| --help

Options:
  --basedir     (-b):  base directory for dumps
  --rsyncargs   (-r):  additional arguments to be passed to rsync
  --listonly    (-l):  list files that would be transferred, don't actually
                       transfer them or delete them
  --dryrun      (-d):  don't rsync, show the commands that would be run
  --verbose     (-v):  show lots of progress messages
  --help        (-h):  display this help message
"""
    sys.stderr.write(usage_message)
    sys.exit(1)


def validate_args(basedir, remainder):
    if basedir is None:
        usage("Mandatory basedir argument is missing")
    elif len(remainder) > 0:
        usage("Unknown option(s) specified: <%s>" % remainder[0])


def process_args():
    """
    get and check validity of command line args
    """
    basedir = None
    dryrun = False
    list_only = False
    rsync_args = []
    verbose = False

    try:
        (options, remainder) = getopt.gnu_getopt(
            sys.argv[1:], "c:r:l:dvh", ["confilefile=", "rsyncargs=", "listonly",
                                        "dryrun", "verbose", "help"])
    except getopt.GetoptError as err:
        usage("Unknown option specified: " + str(err))

    for (opt, val) in options:
        if opt in ["-r", "--rsyncargs"]:
            rsync_args = val.split(',')
        elif opt in ["-b", "--basedir"]:
            basedir = val
        elif opt in ["-l", "--listonly"]:
            list_only = True
        elif opt in ["-d", "--dryrun"]:
            dryrun = True
        elif opt in ["-d", "--verbose"]:
            verbose = True
        elif opt in ["-h", "--help"]:
            usage("Help for this script")

    validate_args(basedir, remainder)
    return dryrun, list_only, rsync_args, verbose, basedir


def do_main():
    dryrun, list_only, rsync_args, verbose, basedir = process_args()
    rsyncer = Rsyncer(rsync_args, basedir, verbose, dryrun, list_only)
    return rsyncer.rsync()


if __name__ == '__main__':
    sys.exit(do_main())
