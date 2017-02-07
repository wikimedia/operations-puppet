"""
Clean up dump dirs which are not set to be rsynced
from source and which are not the most recent run

This is meant to be used after an rsync of
dumps to labs; the rsync itself only copies
new files, and we don't always want to delete
everything. Sometimes status of a directory
is not available (as good) and so it gets excluded
from the rsync, then included again on a
later run. We save ourselves the bandwidth by
leaving those cases alone.
"""

import getopt
import os
import sys
import tempfile
from subprocess import Popen, PIPE


# rsync -a --delete --exclude=/20151026/ --exclude=/20151027/ empty/ public/tenwiki/
class Command(object):
    def __init__(self, verbose, dryrun):
        self.dryrun = dryrun
        self.verbose = verbose

    def run_command(self, command, show_output=False):
        """Run a command with possibly no output. Raises DeleterError on
        non-zero return code."""

        if type(command).__name__ == "list":
            command_string = " ".join(command)
        else:
            command_string = command

        if self.dryrun:
            display("would run %s\n" % command_string)
            return
        if self.verbose:
            display("about to run %s\n" % command_string)

        proc = Popen(command, stderr=PIPE, stdout=PIPE)

        output, error = proc.communicate()
        if output and show_output:
            print output

        if proc.returncode:
            warn("command '%s failed with return code %s and error %s\n"
                 % (command_string, proc.returncode, error))

        # let the caller decide whether to bail or not
        return proc.returncode, output


class DeleterError(Exception):
    pass


def warn(message):
    # maybe this should go to stderr. eh for now...
    print "Warning:", os.getpid(), message
    sys.stdout.flush()

def display(message, continuation=False):
    # caller must add newlines to messages as desired
    if continuation:
        print message,
    else:
        print "Info: (%d) %s" % (os.getpid(), message),
    sys.stdout.flush()


def path_component_is_date(path, fieldno):
    fields = path.split(os.path.sep)
    return bool(len(fields) >= fieldno and fields[fieldno].isdigits() and
                len(fields[fieldno]) == 8)


def get_path_components(path, count):
    """
    return <count> path components from path or the entire
    path if there are not that many

    example: (/a/b/c, 2) returns /a/b  but (/d, 2) returns /d
    """
    if not path.startswith(os.path.sep):
        return None

    fields = path.split(os.path.sep)
    if len(fields) < count + 1:
        return path
    return os.path.sep + os.path.sep.join(fields[0:count])


def get_wiki_subdirs_from_list(file_list):
    """
    given a list of directories and files of the form
    /wikiname/yyyymmdd[/stuff...]
    and maybe other cruft in there too, get out just the directories
    of the form /wikiname/yyyymmdd and return it
    """
    return list(set([get_path_components(path, 2)
                     for path in file_list if path_component_is_date(path, 2)]))


class Deleter(object):
    """
    delete directories and their contents on remote end
    that we don't want to rsync from the source, and
    that are not the most current dumps (those might
    be misflagged as no status and thus failed or some such)
    """

    def __init__(self, dest_host, source_dir_name, dest_dir_name,
                 verbose, dryrun):

        self.rsync_dest_root = dest_host + "::" + dest_dir_name
        self.rsync_source_root = source_dir_name

        self.verbose = verbose
        self.dryrun = dryrun
        # this directory is used by rsync commands as target
        # for one and source for another.
        self.emptydir = tempfile.mkdtemp()
        os.chmod(self.emptydir, 0755)

    def cleanup(self):
        try:
            # get the list of files that we would rsync to an empty
            # target
            would_rsync = self.get_rsyncables()

            # extract directories of the form /wiki/yyyymmdd from
            # list, per wiki
            rsyncable_wiki_subdirs = get_wiki_subdirs_from_list(would_rsync)

            # collect all directory names in the filesystem,
            # of the form /wiki/yyyymmdd that are the most current dumps
            # for each wiki
            all_wiki_subdirs = self.find_latest_wiki_subdirs()

            # add those to the previous list as dirs to keep
            wanted_wiki_subdirs = list(set([rsyncable_wiki_subdirs + all_wiki_subdirs]))

            # construct a -delete rsync command which keeps all the
            # above and deletes "the rest"
            rsync_command = self.get_rsync_command(wanted_wiki_subdirs)

            # run it!
            command_runner = Command(self.verbose, self.dryrun)
            result, output = command_runner.run_command(rsync_command)
        except:
            os.rmdir(self.emptydir)
            if output:
                print output
            raise
        os.rmdir(self.emptydir)
        return result

    def get_rsyncables(self):
        """
        get full list of files rsyncable from source to target,
        by dry run rsync from source to empty directory.
        """
        # get source module name using rsync because the config will
        # have rsync feed us the right thing

        # use empty dir as target dir

        # use rsync to generate the list
        # fixme --list-only or -n?
        rsync_command = ["rsync",
                         "-rlptgon",
                         "--bwlimit=50000",
                         "/data/xmldatadumps/public/",
                         self.emptydir + "/",
                         "--include-from=/data/xmldatadumps/public/rsync-inc-last-3.txt",
                         "--include=/*wik*/",
                         "--exclude=**tmp/",
                         "--exclude=**temp/",
                         "--exclude=**bad/",
                         "--exclude=**save/",
                         "--exclude=**other/",
                         "--exclude=**archive/",
                         "--exclude=**not/",
                         "--exclude=/*",
                         "--exclude=/*/",
                         "--exclude=/*/*/"]

        cmd = Command(self.verbose or self.dryrun, False)
        result, output = cmd.run_command(rsync_command)
        if result:
            raise DeleterError("_failed to get list of files for rsync\n")
        return output

    def find_latest_wiki_subdirs(self):
        wikis = os.listdir(self.rsync_source_root)
        wiki_subdirs = []
        for wiki in wikis:
            subdirs = os.listdir(os.path.join(self.rsync_source_root, wiki))
            subdirs = [subdir for subdir in subdirs if subdir.isdigits() and len(subdir) == 8]
            subdirs = sorted(subdirs, reverse=True)
            if subdirs:
                wiki_subdirs.append(os.path.sep + os.path.join(wiki, subdirs[0]))
        return wiki_subdirs

    def get_rsync_command(self, wiki_subdirs):
        """
        comand that will rsync from empty dir to target, with --delete,
        excluding given directories (and thus excluding them and their
        contents from deletion).
        """
        excludes = ["--exclude=/{0}/".format(dirname) for dirname in wiki_subdirs]
        # keep all top level files on the remote side; some may
        # be locally generated.
        excludes.append("--exclude=/*")
        command = ["/usr/bin/rsync", "-a", "--delete"]
        command.extend(excludes)
        dest_path = self.rsync_dest_root.strip(os.path.sep)
        command.extend([self.emptydir + "/", dest_path + "/"])
        return command


def usage(message=None):
    if message:
        sys.stderr.write("%s\n" % message)
    usage_message = """
Usage: python wmf_rsync_cleanup.py
              [--desthost name]  -sourcedir dirpath
              --destdir dirpath [--dryrun] [--verbose]

This script cleans up dump directories on the target host that are no
longer desired from rsync source and are not the most current run.
(Sometimes the most current dump run may not have a status file which means
it is not picked up for rsync.)
The one exception made is to keep all files in the topmost directory
on the target, so that e.g. indexing can be done locally there without
being removed by us.

--desthost:        the name of the destination dump rsync server if it is not
                   the local host
--sourcedir:       the source path to the top of the dump directory tree
                   containing the files for rsync
--destdir:         the full path to the top of the dest directory tree
                   where rsynced files would land
 --dryrun:         don't do the delete, just show what commands would
                   be run
 --verbose:        print lots of diagnostic output

Example: python wmf_rsync_cleanup.py --desthost labstore1003
                --destdir /srv/dumps --sourcedir /data/xmldatadumps/public
"""
    sys.stderr.write(usage_message)
    sys.exit(1)


def check_args(remainder, source_dir, dest_dir, dest_host):
    if len(remainder) > 0:
        usage("Unknown option specified")

    if not source_dir or not dest_host or not dest_dir:
        usage("Missing required option")

    if not os.path.isdir(source_dir):
        usage("source rsync directory %s"
              " does not exist or is not a directory" % source_dir)


def main():
    dest_host = None
    dest_dir = None
    source_dir = None
    dryrun = False
    verbose = False

    try:
        (options, remainder) = getopt.gnu_getopt(
            sys.argv[1:], "", ["desthost=", "destdir=", "sourcedir=",
                               "rsynclist=", "dryrun", "verbose"])
    except:
        usage("Unknown option specified")

    for (opt, val) in options:
        if opt == "--dest_hostname":
            dest_host = val
        elif opt == "--destdir":
            dest_dir = val
        elif opt == "--sourcedir":
            source_dir = val
        elif opt == "--verbose":
            verbose = True
        elif opt == "--dryrun":
            dryrun = True

    check_args(remainder, source_dir, dest_dir, dest_host)

    source_dir.rstrip('/')
    dest_dir.rstrip('/')

    deleter = Deleter(dest_host, source_dir, dest_dir,
                      verbose, dryrun)

    deleter.cleanup()


if __name__ == "__main__":
    main()
