"""
generate a list of directories and/or files of the last
so many good dump runs
"""
import re
import urllib
import sys
import getopt
import ConfigParser
from subprocess import Popen, PIPE
import os
from os.path import exists, isdir


#############################################################
# This file is maintained by puppet!
# puppet:///modules/snapshot/cron/list-last-n-good-dumps.py
#############################################################


# pylint: disable=broad-except


class DumpListError(Exception):
    """for things that should never happen while generating
    list of dirs/files of dump runs"""
    pass


class WikiConfig(object):
    """configuration settings from file:
    path to temp directory, where local cache is stored
    path to public directory, where output files are written
    path to list of all wikis, one per line"""
    def __init__(self, configfile):
        home = os.path.dirname(sys.argv[0])
        files = [
            os.path.join(home, configfile),
            "/etc/wikidump.conf",
            os.path.join(os.getenv("HOME"), ".wikidump.conf")]
        defaults = {
            # "wiki": {
            "dblist": "/dumps/all.dblist",
            # "output": {
            "public": "/dumps/public",
            "temp": "/dumps/temp",
        }
        self.conf = ConfigParser.SafeConfigParser(defaults)
        self.conf.read(files)
        if not self.conf.has_section('output'):
            self.conf.add_section('output')
        if not self.conf.has_section('wiki'):
            self.conf.add_section('wiki')
        self.public_dir = self.conf.get("output", "public")
        self.temp_dir = self.conf.get("output", "temp")
        db_list = sorted([db.strip() for db in open(
            self.conf.get("wiki", "dblist")).readlines()])
        self.db_list = [dbname for dbname in db_list if dbname]


def get_projectlist_copy_fname():
    """returns name of local cache of the project list"""
    return "all.dblist"


def get_dir_status(dir_to_check):
    """read and return text from the status html file for a given dump"""
    if isdir(dir_to_check):
        try:
            statusfile = os.path.join(dir_to_check, "status.html")
            fdesc = open(statusfile, "r")
            text = fdesc.read()
            fdesc.close()
        except Exception:
            # if there is no status file, the dir could have any
            # kind of random junk in it so don't risk it
            return None
        return text
    return None


def get_first_dir(dirs, dir_to_check):
    """
    given a sorted list of subdir names (expect them to be
    date strings yyyymmdd and sorted earliest to latest),
    and a base dir of these subdirs,
    find and return the first subdir name that has a non-failed
    dump run status.

    if there are none, return the name of the first subdir that
    has a readable status file.

    if there are none of those, return None
    """
    if not dirs:
        return False
    for day in dirs:
        text = get_dir_status(os.path.join(dir_to_check, day))
        if text is None:
            continue
        if "failed" not in text:
            return day

    # no dump in there that's not failed. meh.
    # try again and take the first one we can read
    for day in dirs:
        text = get_dir_status(os.path.join(dir_to_check, day))
        if text is None:
            continue
        return day

    # no dumps with status we can read. give up
    return False


def fillin_fname_templ(templ, number):
    """given a filename template which expects to have a number
    plugged into it someplace (indicated by a '%s'), make
    the substitution and return the new name"""
    if '%s' in templ:
        return templ % number
    else:
        return templ


def is_in_progress(dir_to_check):
    """
    check if status of run in specified directory is
    in progress, return True if so, False otherwise
    or if status cannot be checked
    """
    text = get_dir_status(dir_to_check)
    if text is None:
        return False
    return bool("in-progress" in text)


class ProjectList(object):
    """
    manage list of projects (wikis), retrieve from
    flat file or via a url
    """
    def __init__(self, config, paths):
        self.config = config
        self.paths = paths

    def get_projlist_from_urlorconf(self, projects_url):
        """try to retrieve the list of known projects from a specified
        url; if there was no url given, try contents read from the filename
        given for 'dblist' in the config file"""
        contents = ""
        if projects_url:
            try:
                # e.g. http://noc.wikimedia.org/conf/all.dblist
                infd = urllib.urlopen(projects_url)
                contents = infd.read()
                infd.close()
            except Exception:
                sys.stderr.write("Warning: Failed to retrieve project"
                                 " list via http, using old list\n")

        elif self.config.db_list:
            try:
                contents = '\n'.join(self.config.db_list) + '\n'
            except Exception:
                sys.stderr.write("Warning: Failed to retrieve good"
                                 " project list from %s as specified"
                                 " in config file, using old list\n"
                                 % self.config.db_list)

        return contents

    def get_proj_list_from_old_file(self):
        """We try to save a temp copy of the list of known projects
        on every run; retrieve that copy"""

        contents = ""

        tempdir = self.get_tempdir()
        dblist = os.path.join(tempdir, get_projectlist_copy_fname())

        # read previous contents, if any...
        try:
            infd = open(dblist, "r")
            contents = infd.read()
            infd.close()
        except Exception:
            sys.stderr.write("Warning: Old project list %s from"
                             " previous run is unavailable\n" % dblist)
        return contents

    def save_projectlist(self, contents):
        """save local copy of the project list we presumably
        retrieved from elsewhere"""
        tempdir = self.get_tempdir()
        dblist = os.path.join(tempdir, get_projectlist_copy_fname())

        try:
            # ok it passes the smell test (or we filled it with
            # the old contents), save this as the new list
            if not exists(tempdir):
                os.makedirs(tempdir)
            outfd = open(dblist, "wt")
            outfd.write(contents)
            outfd.close()
        except Exception:
            # we can still do our work so don't die, but do complain
            sys.stderr.write("Warning: Failed to save project list"
                             " to file %s\n" % dblist)

    def load_projectlist(self, projects_url):
        """Get and store the list of all projects known to us; this
        includes closed projects but may not include all projects
        that ever existed, for example tlhwik."""

        projects = []
        old_contents = self.get_proj_list_from_old_file()
        if len(old_contents):
            old_projects = old_contents.splitlines()
        else:
            old_projects = []

        contents = self.get_projlist_from_urlorconf(projects_url)
        if len(contents):
            projects = contents.splitlines()
        else:
            projects = []

        # check that this list is not comlete crap compared to the
        # previous list, if any, before we get started. arbitrarily:
        # a change of more than 5% in size
        if (len(old_projects) and
                float(len(projects)) / float(len(old_projects)) < .95):
            sys.stderr.write("Warning: New list of projects is much"
                             " smaller than previous run, %s"
                             " compared to %s\n" % (len(projects),
                                                    len(old_projects)))
            sys.stderr.write("Warning: Using old list; remove old list"
                             " %s to override\n"
                             % os.path.join(self.get_tempdir(),
                                            get_projectlist_copy_fname()))

            projects = old_projects
            contents = old_contents

        if not len(projects):
            raise DumpListError("List of projects is empty, giving up")

        self.save_projectlist(contents)
        return projects

    def get_tempdir(self):
        """returns the full path to a directory for temporary files"""
        tempdir = self.config.temp_dir
        if not tempdir:
            # FIXME
            tempdir = self.paths.get_abs_outdirpath('tmp')
        return tempdir


class OutputPaths(object):
    """
    keep track of all output file templates and names

    this includes dir listings, file listings, rsync inclusion listings,
    temp files
    """
    def __init__(self, config, templs, output_dir):
        self.config = config
        self.templs = templs
        self.output_dir = output_dir
        if self.output_dir and self.output_dir.endswith(os.sep):
            self.output_dir = self.output_dir[:-1 * len(os.sep)]
        self.types = {'dirlist': 'dir_list_templ',
                      'filelist': 'file_list_templ',
                      'rsynclist': 'rsync_incl_templ'}

    def get_abs_pubdirpath(self, name):
        """return full path to the location of public dumps,
        as specified in the config file for the entry 'publicdir'"""
        return os.path.join(self.config.public_dir, name)

    def get_abs_outdirpath(self, name):
        """return full path to the location where output files will
        be written"""
        if self.output_dir:
            return os.path.join(self.output_dir, name)
        else:
            return os.path.join(self.config.public_dir, name)

    def get_list_output_path(self, num, name):
        """return full path to output file for the specific
        sort of list"""
        try:
            return self.get_abs_outdirpath(fillin_fname_templ(
                self.templs[self.types[name]], num) + ".tmp")
        except Exception:
            return None

    def get_output_paths(self, num, temp=True):
        """return list of all output file paths"""
        return [self.get_abs_outdirpath(
            fillin_fname_templ(self.templs[templ_name], num) +
            (".tmp" if temp else "")) for templ_name in self.templs.keys()]

    def list_wanted(self, name):
        """return true if an outputted list of the specific type is wanted
        (output filename has been passed by the caller)"""
        try:
            return bool(self.types[name] in self.templs and self.templs[self.types[name]])
        except Exception:
            return None


class DumpList(object):
    """This class generates a list of the last n sets of XML
    dump files per project that were successful, adding failed
    and/or incomplete dumps to the list if there are not n
    successful dumps available; n varies across a specified
    list of numbers of dumps desired, and the corresponding
    lists are produced for all dumps in one pass."""

    def __init__(self, config, dumps_num_list, paths, flags):
        """constructor"""

        self.config = config
        self.paths = paths
        self.projectlist = ProjectList(config, paths)
        self.dumps_num_list = dumps_num_list
        self.max_dump_num = max(self.dumps_num_list)
        self.flags = flags

    def list_dump_for_proj(self, project):
        """get list of dump directories for a given project
        ordered by good dumps first, most recent to oldest, then
        failed dumps most rcent to oldest, and finally incomplete
        dumps most recent to oldest.
        files from in-progress dumps will only be written to the
        rsync include file.
        """
        dir_to_check = self.paths.get_abs_pubdirpath(project)
        if not exists(dir_to_check):
            return [], None

        dirs = os.listdir(dir_to_check)
        # dirs have the format yyyymmdd and we want only those and
        # listed most recent first by date, not by ctime or mtime.
        ymd_pattern = r'^2[0-1][0-9]{6}$'
        dirs = [d for d in dirs if re.search(ymd_pattern, d)]
        dirs.sort()
        dirs.reverse()

        dirs_failed = []
        dirs_complete = []
        dirs_other = []
        dir_in_progress = None
        dirs_reported = []

        dir_first = get_first_dir(dirs, dir_to_check)
        if not dir_first:
            # never dumped
            return dirs_reported

        text = get_dir_status(os.path.join(dir_to_check, dir_first))
        if "in-progress" in text:
            dir_in_progress = dir_first
            dirs.pop(0)
        for day in dirs:
            text = get_dir_status(os.path.join(dir_to_check, day))
            if text is None:
                continue

            if "failed" in text:
                dirs_failed.append(day)
            elif "Dump complete" in text:
                dirs_complete.append(day)
            elif "in-progress" not in text:
                dirs_other.append(day)

        dirs_reported.extend(dirs_complete)
        dirs_reported.extend(dirs_other)
        dirs_reported.extend(dirs_failed)
        return dirs_reported, dir_in_progress

    def get_files_with_extensions(self, dir_name, extensions):
        """pass in regexp of extensions of files wanted
        from directory; receive a list of all such files in
        supplied dir name, or [] if there are none or there is
        some error"""
        files_wanted = []
        try:
            dir_contents = os.listdir(dir_name)
            files_wanted = ([os.path.join(dir_name, f) for f in dir_contents
                             if re.search(extensions, f)])
            if self.flags['relative']:
                files_wanted = [self.strip_pubdir(f) for f in files_wanted]
        except Exception:
            pass
        return files_wanted

    def get_completed_files(self, dir_name):
        """get files that are completely written for a dump,
         by looking at the md5sums list."""
        # we want only files that are complete, read the list out of the uh. FIXME
        # check an md5sum file for the names :-/ dewiki-20161201-md5sums.txt
        files_wanted = []
        dir_components = dir_name.split(os.path.sep)
        project, date = dir_components[-2], dir_components[-1]
        filename = "%s-%s-md5sums.txt" % (project, date)
        try:
            infd = open(os.path.join(dir_name, filename), "r")
            entries = infd.readlines()
            infd.close()
            files_wanted_shortnames = [entry.rstrip().split()[-1] for entry in entries]
            files_wanted = [os.path.join(dir_name, f) for f in files_wanted_shortnames]
            if self.flags['relative']:
                files_wanted = [self.strip_pubdir(f) for f in files_wanted]
        except Exception:
            pass
        return files_wanted

    def get_fnames_from_dir(self, dir_name):
        """given a dump directory (the full path to a specific run),
        get the names of the files we want to list; we only pick
        up the files that are part of the public run, not scratch or other
        files, and the filenames are either full paths or are relative
        to the base directory of the public dumps, depending on
        user-specified options.
        if the dump has 'in-progress' status, we return that info too.
        """
        in_progress = is_in_progress(dir_name)
        files_wanted = []
        if not in_progress:
            # we want all the files
            files_wanted = self.get_files_with_extensions(
                dir_name, r'(\.gz|\.bz2|\.7z|\.html|\.txt|\.xml|\.css|\.json)$')
        else:
            # these files have been completed for the dump run
            files_wanted = self.get_completed_files(dir_name)
            # these files do not contain dump job output but we want them, like
            # index.html files, files with md5sums, status files, etc
            files_wanted.extend(self.get_files_with_extensions(
                dir_name, r'(\.html|\.txt|\.css|\.json)$'))
        return files_wanted

    def truncate_outfiles(self):
        """call this once at the beginning of any run to truncate
        all output files before beginning to write to them"""
        for num in self.dumps_num_list:
            paths = self.paths.get_output_paths(num)
            for path in paths:
                try:
                    fdesc = open(path, "wt")
                    fdesc.close()
                except Exception:
                    pass

    def write_dirnames(self, dirs, project, output_type='dirlist', wildcard=False):
        """write supplied list of dirs from the project dump.
        by default, write these to the file intended for dir lists, though
        another output type may be specified.
        by default, write the full path to the directory, one per line;
        if 'wildcard' is True, then write each directory with a trailing slash and '*'
        as a wildcard match for all files in that directory."""
        if not dirs:
            return
        if not self.paths.list_wanted(output_type):
            return

        dirs = [os.path.join(self.paths.get_abs_pubdirpath(project), dirname) for dirname in dirs]
        if self.flags['relative']:
            dirs = [self.strip_pubdir(dirname) for dirname in dirs]
        if wildcard:
            dirs = [os.path.join(dirname, '*') for dirname in dirs]

        if dirs:
            for num in self.dumps_num_list:
                output_path = self.paths.get_list_output_path(num, output_type)
                dirsfd = open(output_path, "a")
                dirsfd.write('\n'.join(dirs[0: int(num)]) + '\n')
                dirsfd.close()

    def write_filenames(self, dirs, project, output_type='filelist'):
        """write list of filenames in given dirs from the project dump"""
        if not dirs:
            return
        if not self.paths.list_wanted(output_type):
            return

        dirs = [os.path.join(self.paths.get_abs_pubdirpath(project), dirname) for dirname in dirs]
        if dirs:
            fnames_to_write = []
            for dirname in dirs:
                fnames_to_write.append(self.get_fnames_from_dir(dirname))

            if fnames_to_write:
                for num in self.dumps_num_list:
                    output_path = self.paths.get_list_output_path(num, 'filelist')
                    filesfd = open(output_path, "a")
                    # fix me how to flatten, meh
                    filesfd.write('\n'.join(fname for file_list in fnames_to_write[0: int(num)]
                                            for fname in file_list) + '\n')
                    filesfd.close()

    def write_rsynclists(self, dirs, dir_in_progress, project, output_type='rsynclist'):
        """write list of dirs plus in-progress files for rsync inclusion,
        for the project dump"""
        if not self.paths.list_wanted('rsynclist'):
            return

        if dir_in_progress:
            self.write_dirnames([dir_in_progress], project, output_type)
            # write list of dump-related files from the latest in-progress directory, if any,
            # to all rsync inclusion lists
            fnames_done = self.get_fnames_from_dir(os.path.join(
                self.paths.get_abs_pubdirpath(project), dir_in_progress))
            if fnames_done:
                for num in self.dumps_num_list:
                    output_path = self.paths.get_list_output_path(num, 'rsynclist')
                    filesfd = open(output_path, "a")
                    filesfd.write('\n'.join(fnames_done) + '\n')
                    filesfd.close()
        self.write_dirnames(dirs, project, output_type)
        # for the directories of runs not in progress, we want to match all files
        self.write_dirnames(dirs, project, output_type, wildcard=True)

    def write_all_lists(self, projects):
        """for a given project, write all dirs and all files from
        the last n dumps to various files with n varying as
        specified by the user"""
        for project in projects:
            dirs, dir_in_progress = self.list_dump_for_proj(project)
            self.write_dirnames(dirs, project)
            self.write_filenames(dirs, project)
            self.write_rsynclists(dirs, dir_in_progress, project)

    def strip_pubdir(self, line):
        """remove the path to the public dumps directory from
        the beginning of the suppplied line, if it exists"""
        if line.startswith(self.config.public_dir + os.sep):
            line = line[len(self.config.public_dir):]
        return line

    def convert_fnames_for_rsyncinput(self, fpath):
        """prep list of filenames so that it can be passed
        to rsync --list-only"""

        # to make this work we have to feed it a file with the filenames
        # with the publicdir stripped off the front, if it's there
        infd = open(fpath, "r")
        outfd = open(fpath + ".relpath", "w")
        lines = infd.readlines()
        infd.close()
        for line in lines:
            if not self.flags['relative']:
                outfd.write(self.strip_pubdir(line))
            else:
                outfd.write(line)
        outfd.close()

    def do_rsync_list_only(self, fpath):
        """produce long listing of files from a specific dump run,
        by passing the file list to rsync --list-only"""
        command = ["/usr/bin/rsync", "--list-only", "--no-h",
                   "--files-from", fpath + ".relpath",
                   self.config.public_dir,
                   "dummy", ">", fpath + ".rsync"]
        command_string = " ".join(command)
        proc = Popen(command_string, shell=True, stderr=PIPE)
        # output will be None, we can ignore it
        dummy_output, error = proc.communicate()
        if proc.returncode:
            raise DumpListError(
                "command '" + command_string +
                ("' failed with return code %s " % proc.returncode) +
                " and error '" + error + "'")

    def get_toplevelfiles(self):
        """
        list .html, .json, .css, .txt files in top level dir
        test, with "" does this work?
        """
        files_in_dir = [f for f in os.listdir(self.paths.get_abs_pubdirpath(""))
                        if f.endswith(".html") or f.endswith(".txt") or f.endswith(".old")
                        or f.endswith(".css") or f.endswith(".json")]
        return files_in_dir

    def write_toplevelfiles(self):
        """write the html and txt files in the top level directory to
        the appropriate output files."""
        fnames_to_write = self.get_toplevelfiles()
        if fnames_to_write:
            for num in self.dumps_num_list:
                output_paths = [self.paths.get_list_output_path(num, 'filelist'),
                                self.paths.get_list_output_path(num, 'rsynclist')]
                for path in output_paths:
                    if path is not None:
                        filesfd = open(path, "a")
                        filesfd.write('\n'.join(fnames_to_write) + '\n')
                        filesfd.close()

    def write_rsyncinput_lists(self):
        """write list of files generated by rsync --list-only"""
        for num in self.dumps_num_list:
            output_paths = self.paths.get_output_paths(num, temp=False)
            for path in output_paths:
                if path is not None:
                    self.convert_fnames_for_rsyncinput(path)
                    self.do_rsync_list_only(path)

    def rename_files(self):
        """move current output files to .old, new output files from
        .tmp to regular names"""
        for num in self.dumps_num_list:
            output_paths = self.paths.get_output_paths(num, temp=False)
            # do this last so that if someone is using the file
            # in the meantime, they  aren't interrupted
            for path in output_paths:
                if path is not None:
                    if exists(path + ".tmp"):
                        if exists(path):
                            os.rename(path, path + ".old")
                        os.rename(path + ".tmp", path)
                    else:
                        raise DumpListError("No output file %s created. "
                                            "Something is wrong." % path + ".tmp")

    def gen_dumpfile_dirlists(self, projects):
        """produce all files of dir lists and file lists from
        all desired dump runs for all projects"""
        self.truncate_outfiles()
        if self.flags['top_level']:
            self.write_toplevelfiles()
        self.write_all_lists(projects)
        self.rename_files()
        if self.flags['rsynclists']:
            self.write_rsyncinput_lists()


def usage(message=None):
    """display usage message, call when we encounter an options error"""
    if message:
        sys.stderr.write(message + "\n\n")
    usage_message = """Usage: list-last-n-good-dumps.py [--dumpsnumber n]
                [--configfile filename] [--relpath] [--rsynclists]
                [--dirlisting filename-format] [--filelisting filename-format]
                [--rsynclisting filename-format]

Options:

configfile  -- path to config file used to generate dumps
               default value: wikidump.conf
dumpsnumber -- number of dumps to list; this may be one number, in which case
               one set of files will be produced, or it can be a
               comma-separated list of numbers, in which case a set of files
               will be produced for each number of dumps
               default value: 5
outputdir   -- directory in which to write all file listings; otherwise they
               will be written to the value specified in the config file for
               publicdir
projectsurl -- use this url to retrieve the list of projects rather than the
               value specified for 'dblist' in the config file.  Example:
               http://localhost/dumpsconfig/all.dblist
relpath     -- generate all lists with paths relative to the public directory
               specified in the configuration file, instead of writing out
               the full path
               default value: False
rsynclists  -- for each file that is produced, write a second file with the
               same name but ending in \".rsync\", which is produced by
               feeding the original file as input to rsync with the
               --list-only option
               default value: False
toplevel    -- include .html, .txt, .css and .json files from the top level
               directory in the filename listing

At least one of the three options below must be specified:

dirlisting   -- produce a file named with the specified format listing the
                directories (e.g. /aawiki/20120309) with no filenames
                default value: none
filelisting  -- produce a file named with the specified format listing the
                filenames (e.g. /aawiki/20120309/aawiki-20120309-abstract.xml)
                with no dirnames
                default value: none
rsynclisting -- produce a file named with the specified format listing the
                directories of complete dumps (e.g. /aawiki/20120309/) and
                the filenames of completed files from in-progress dumps
                (e.g. /aawiki/20120309/aawiki-20120309-abstract.xml)
                default value: none

Example use:
python list-last-n-good-dumps.py --dumpsnumber 3,5
               --dirlisting rsync-dirs-last-%%s.txt
               --configfile /backups/wikidump.conf.testing --rsynclists
               --relpath
"""
    sys.stderr.write(usage_message)
    sys.exit(1)


def check_options(dumps_num_list, templs):
    """check the supplied options for validity"""
    for dnum in dumps_num_list:
        if not dnum.isdigit() or not int(dnum):
            usage("dumpsnumber must be a number or a comma-separated"
                  " list of numbers each greater than 0")

    if not len(templs):
        usage("At least one of --dirlisting, --filelisting, or"
              " --rsynclisting must be specified")

    for (templ_name, option_name) in [('file_list_templ', "filelisting"),
                                      ('dir_list_templ', "dirlisting"),
                                      ('rsync_incl_templ', "rsynclisting")]:
        if (templ_name in templs and templs[templ_name] and len(dumps_num_list) > 1
                and '%s' not in templs[templ_name]):
            usage("In order to write more than one output file with"
                  " dump runs, the value specified for %s"
                  " must contain '%s' which will be replaced by the"
                  " number of dumps to write to the given output file"
                  % option_name)


def get_flag_defaults():
    """return default values for command line flags"""
    return {'relative': False, 'rsynclists': False, 'top_level': False}


def get_flags(opt, flags):
    """parse command line flags, set and return appropriate values"""
    if opt == '--relpath':
        flags['relative'] = True
    if opt == '--rsynclists':
        flags['rsynclists'] = True
    if opt == "--toplevel":
        flags['top_level'] = True


def get_templs(opt, val, templs):
    """parse options providing templates of output file names,
    returning True if an option matches for parsing, False otherwise"""
    if opt == "--dirlisting":
        templs['dir_list_templ'] = val
    elif opt == "--filelisting":
        templs['file_list_templ'] = val
    elif opt == "--rsynclisting":
        templs['rsync_incl_templ'] = val
    else:
        return False
    return True


def do_main():
    """main entry point.
    set default option values,
    read, parse and check options from command line,
    load list of known wikis,
    generate list of files and/or dirs of good dump runs"""

    configfile = "wikidump.conf"
    dumps_num = "5"
    flags = get_flag_defaults()
    templs = {}
    projects_url = None
    output_dir = None

    try:
        (options, remainder) = getopt.gnu_getopt(
            sys.argv[1:], "", ['configfile=', 'dumpsnumber=',
                               'outputdir=', 'projectlisturl=',
                               'relpath', 'rsynclists',
                               'toplevel', 'dirlisting=',
                               'filelisting=', 'rsynclisting='])
    except Exception:
        usage("Unknown option specified")

    if len(remainder):
        usage("Unknown option specified: %s" % remainder[0])

    for (opt, val) in options:
        if opt == "--configfile":
            configfile = val
        elif opt == "projectlisturl":
            projects_url = val
        elif opt == '--dumpsnumber':
            dumps_num = val
        elif opt == '--outputdir':
            output_dir = val
        elif not get_templs(opt, val, templs):
            get_flags(opt, flags)

    if ',' not in dumps_num:
        dumps_num_list = [dumps_num.strip()]
    else:
        dumps_num_list = [d.strip() for d in dumps_num.split(',')]

    check_options(dumps_num_list, templs)

    config = WikiConfig(configfile)
    dlist = DumpList(config, dumps_num_list, OutputPaths(config, templs, output_dir), flags)
    projects = dlist.projectlist.load_projectlist(projects_url)
    dlist.gen_dumpfile_dirlists(projects)


if __name__ == "__main__":
    do_main()
