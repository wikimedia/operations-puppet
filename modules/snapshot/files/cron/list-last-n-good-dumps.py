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
    pass


class WikiConfig(object):

    def __init__(self, configfile):
        home = os.path.dirname(sys.argv[0])
        self.files = [
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
        self.conf.read(self.files)
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
    """returns name we use for the local copy of the project list"""
    return "all.dblist"


def get_dir_status(dir_to_check, day):
    if isdir(os.path.join(dir_to_check, day)):
        try:
            statusfile = os.path.join(dir_to_check, day, "status.html")
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
    if not dirs:
        return False
    for day in dirs:
        text = get_dir_status(dir_to_check, day)
        if text is None:
            continue
        if "failed" not in text:
            return day

    # no dump in there that's not failed. meh.
    # try again and take the first one we can read
    for day in dirs:
        text = get_dir_status(dir_to_check, day)
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


class DumpList(object):
    """This class generates a list of the last n sets of XML
    dump files per project that were successful, adding failed
    and/or incomplete dumps to the list if there are not n
    successful dumps available; n varies across a specified
    list of numbers of dumps desired, and the corresponding
    lists are produced for all dumps in one pass."""

    def __init__(self, config, dumps_num_list, relative,
                 rsynclists, dir_list_templ, file_list_templ,
                 output_dir, projects_url, top_level):
        """constructor"""

        self.config = config
        self.dumps_num_list = dumps_num_list
        self.max_dump_num = max(self.dumps_num_list)
        self.relative = relative
        self.rsynclists = rsynclists
        self.dir_list_templ = dir_list_templ
        self.file_list_templ = file_list_templ
        self.output_dir = output_dir
        if self.output_dir and self.output_dir.endswith(os.sep):
            self.output_dir = self.output_dir[:-1 * len(os.sep)]
        self.projects_url = projects_url
        self.top_level = top_level
        self.contents = None
        self.projects = []

    def get_projlist_from_urlorconf(self):
        """try to retrieve the list of known projects from a specified
        url; if there was no url given, try contents read from the filename
        given for 'dblist' in the config file"""
        contents = ""
        if self.projects_url:
            try:
                # e.g. http://noc.wikimedia.org/conf/all.dblist
                infd = urllib.urlopen(self.projects_url)
                self.contents = infd.read()
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

    def get_tempdir(self):
        """returns the full path to a directory for temporary files"""
        tempdir = self.config.temp_dir
        if not tempdir:
            tempdir = self.get_abs_outdirpath('tmp')
        return tempdir

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

    def load_projectlist(self):
        """Get and store the list of all projects known to us; this
        includes closed projects but may not include all projects
        that ever existed, for example tlhwik."""

        self.projects = []
        old_contents = self.get_proj_list_from_old_file()
        if len(old_contents):
            old_projects = old_contents.splitlines()
        else:
            old_projects = []

        self.contents = self.get_projlist_from_urlorconf()
        if len(self.contents):
            self.projects = self.contents.splitlines()
        else:
            self.projects = []

        # check that this list is not comlete crap compared to the
        # previous list, if any, before we get started. arbitrarily:
        # a change of more than 5% in size
        if (len(old_projects) and
                float(len(self.projects)) / float(len(old_projects)) < .95):
            sys.stderr.write("Warning: New list of projects is much"
                             " smaller than previous run, %s"
                             " compared to %s\n" % (len(self.projects),
                                                    len(old_projects)))
            sys.stderr.write("Warning: Using old list; remove old list"
                             " %s to override\n"
                             % os.path.join(self.get_tempdir(),
                                            get_projectlist_copy_fname()))

            self.projects = old_projects
            self.contents = old_contents

        if not len(self.projects):
            raise DumpListError("List of projects is empty, giving up")

        self.save_projectlist(self.contents)

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

    def list_dump_for_proj(self, project):
        """get list of dump directories for a given project
        ordered by good dumps first, most recent to oldest, then
        failed dumps most rcent to oldest, and finally incomplete
        dumps most recent to oldest"""
        dir_to_check = self.get_abs_pubdirpath(project)
        if not exists(dir_to_check):
            return []

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

        dirs_reported = []

        dir_first = get_first_dir(dirs, dir_to_check)
        if not dir_first:
            # never dumped
            return dirs_reported

        for day in dirs:
            if day == dir_first:
                continue
            text = get_dir_status(dir_to_check, day)
            if text is None:
                continue

            if "failed" in text:
                dirs_failed.append(day)
            elif "Dump complete" in text:
                dirs_complete.append(day)
            else:
                dirs_other.append(day)

        dirs_reported.append(dir_first)
        dirs_reported.extend(dirs_complete)
        dirs_reported.extend(dirs_other)
        dirs_reported.extend(dirs_failed)
        return dirs_reported

    def list_file_templs(self):
        """list the templates for filenames that were provided
        by the caller, i.e. the template for the lists of files of
        the last n dumps, and the template for the lists of dirs
        of the last n dumps"""
        fname_templs = []
        fname_templs.extend([self.dir_list_templ, self.file_list_templ])
        return [templ for templ in fname_templs if templ]

    def get_fnames_from_dir(self, dir_name):
        """given a dump directory (the full path to a specific run),
        get the names of the files we want to list; we only pick
        up the files that are part of the public run, not scratch or other
        files, and the filenames are either full paths or are relative
        to the base directory of the public dumps, depending on
        user-specified options."""
        files_wanted = []
        files_wanted_pattern = r'(\.gz|\.bz2|\.7z|\.html|\.txt|\.xml)$'
        if self.file_list_templ:
            dir_contents = os.listdir(dir_name)
            files_wanted = ([os.path.join(dir_name, f) for f in dir_contents
                             if re.search(files_wanted_pattern, f)])
            if self.relative:
                files_wanted = [self.strip_pubdir(f) for f in files_wanted]
        return files_wanted

    def truncate_outfiles(self):
        """call this once at the beginning of any run to truncate
        all output files before beginning to write to them"""
        fname_templs = self.list_file_templs()
        for templ in fname_templs:
            for num in self.dumps_num_list:
                fname = fillin_fname_templ(templ, num)
                try:
                    fdesc = open(self.get_abs_outdirpath(fname + ".tmp"), "wt")
                    fdesc.close()
                except Exception:
                    pass

    def write_filenames(self, num, dir_name, fnames_to_write,
                        skip_dirs=False):
        """write supplied list of filenames from the project dump
        of a particular run into files named as specified by the
        user, and write the project dump directory name into
        separate files named as specified by the user"""
        if self.file_list_templ:
            output_fname = self.get_abs_outdirpath(
                fillin_fname_templ(
                    self.file_list_templ, num) + ".tmp")
            filesfd = open(output_fname, "a")
            filesfd.write('\n'.join(fnames_to_write))
            filesfd.write('\n')
            filesfd.close()
        if self.dir_list_templ and not skip_dirs:
            output_fname = self.get_abs_outdirpath(
                fillin_fname_templ(
                    self.dir_list_templ, num) + ".tmp")
            if self.relative:
                dir_name = self.strip_pubdir(dir_name)
            dirsfd = open(output_fname, "a")
            dirsfd.write(dir_name + '\n')
            dirsfd.close()

    def write_file_dir_lists_for_proj(self, project):
        """for a given project, write all dirs and all files from
        the last n dumps to various files with n varying as
        specified by the user"""
        dirs = self.list_dump_for_proj(project)
        fnames_to_write = None
        index = 0
        project_path = self.get_abs_pubdirpath(project)
        while index < len(dirs):
            if index >= self.max_dump_num:
                break
            if self.file_list_templ:
                fnames_to_write = self.get_fnames_from_dir(os.path.join(
                    project_path, dirs[index]))
            for dnum in self.dumps_num_list:
                if index < int(dnum):
                    self.write_filenames(dnum, os.path.join(
                        project_path, dirs[index]), fnames_to_write)
            index = index + 1

    def strip_pubdir(self, line):
        """remove the path to the public dumps directory from
        the beginning of the suppplied line, if it exists"""
        if line.startswith(self.config.public_dir + os.sep):
            line = line[len(self.config.public_dir):]
        return line

    def convert_fnames_for_rsyncin(self, fname):
        """prep list of filenames so that it can be passed
        to rsync --list-only"""

        # to make this work we have to feed it a file with the filenames
        # with the publicdir stripped off the front, if it's there
        fpath = self.get_abs_outdirpath(fname)
        infd = open(fpath, "r")
        outfd = open(fpath + ".relpath", "w")
        lines = infd.readlines()
        infd.close()
        for line in lines:
            if not self.relative:
                outfd.write(self.strip_pubdir(line))
            else:
                outfd.write(line)
        outfd.close()

    def do_rsync_list_only(self, fname):
        """produce long listing of files from a specific dump run,
        by passing the file list to rsync --list-only"""
        fpath = self.get_abs_outdirpath(fname)
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
        # list *html and *txt files in top level dir
        # test, with "" does this work?
        files_in_dir = [f for f in os.listdir(self.get_abs_pubdirpath(""))
                        if f.endswith(".html") or f.endswith(".txt")]
        return files_in_dir

    def write_toplevelfiles(self):
        """write the html and txt files in the top level dirextory to
        the appropriate output files."""
        fnames_to_write = self.get_toplevelfiles()
        for dnum in self.dumps_num_list:
            self.write_filenames(dnum, None, fnames_to_write, skip_dirs=True)

    def gen_dumpfile_dirlists(self):
        """produce all files of dir lists and file lists from
        all desired dump runs for all projects"""
        self.truncate_outfiles()
        if self.top_level:
            self.write_toplevelfiles()
        for proj in self.projects:
            self.write_file_dir_lists_for_proj(proj)

        fname_templs = self.list_file_templs()
        for templ in fname_templs:
            for num in self.dumps_num_list:
                fdesc = fillin_fname_templ(templ, num)
                # do this last so that if someone is using the file
                # in the meantime, they  aren't interrupted
                fpath = self.get_abs_outdirpath(fdesc)
                if exists(fpath + ".tmp"):
                    if exists(fpath):
                        os.rename(fpath, fpath + ".old")
                    os.rename(fpath + ".tmp", fpath)
                else:
                    raise DumpListError("No output file %s created. "
                                        "Something is wrong." % fpath + ".tmp")

                if self.rsynclists:
                    self.convert_fnames_for_rsyncin(fdesc)
                    self.do_rsync_list_only(fdesc)


def usage(message=None):
    """display usage message, call when we encounter an options error"""
    if message:
        sys.stderr.write(message + "\n\n")
    usage_message = """Usage: list-last-n-good-dumps.py [--dumpsnumber n]
                [--configfile filename] [--relpath] [--rsynclists]
                [--dirlisting filename-format] [--filelisting filename-format]

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
toplevel    -- include .html and .txt files from the top level directory in
               the filename listing

One of the two options below must be specified:

dirlisting  -- produce a file named with the specified format listing the
               directories (e.g. /aawiki/20120309) with no filenames
               default value: none
filelisting -- produce a file named with the specified format listing the
               filenames (e.g. /aawiki/20120309/aawiki-20120309-abstract.xml)
               with no dirnames
               default value: none

Example use:
python list-last-n-good-dumps.py --dumpsnumber 3,5
               --dirlisting rsync-dirs-last-%%s.txt
               --configfile /backups/wikidump.conf.testing --rsynclists
               --relpath
"""
    sys.stderr.write(usage_message)
    sys.exit(1)


def do_main():
    configfile = "wikidump.conf"
    dumps_num = "5"
    relative = False
    rsynclists = False
    top_level = False
    dir_list_templ = None
    file_list_templ = None
    projects_url = None
    output_dir = None

    try:
        (options, remainder) = getopt.gnu_getopt(
            sys.argv[1:], "", ['configfile=', 'dumpsnumber=',
                               'outputdir=', 'projectlisturl=',
                               'relpath', 'rsynclists',
                               'toplevel', 'dirlisting=',
                               'filelisting='])
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
        elif opt == '--relpath':
            relative = True
        elif opt == '--rsynclists':
            rsynclists = True
        elif opt == "--dirlisting":
            dir_list_templ = val
        elif opt == "--filelisting":
            file_list_templ = val
        elif opt == "--toplevel":
            top_level = True

    if ',' not in dumps_num:
        dumps_num_list = [dumps_num.strip()]
    else:
        dumps_num_list = [d.strip() for d in dumps_num.split(',')]

    for dnum in dumps_num_list:
        if not dnum.isdigit() or not int(dnum):
            usage("dumpsnumber must be a number or a comma-separated"
                  " list of numbers each greater than 0")

    if not dir_list_templ and not file_list_templ:
        usage("At least one of --dirlisting or"
              " --filelisting must be specified")

    if (file_list_templ and len(dumps_num_list) > 1 and
            '%s' not in file_list_templ):
        usage("In order to write more than one output file with"
              " dump runs, the value specified for filelisting"
              " must contain '%s' which will be replaced by the"
              " number of dumps to write to the given output file")

    if (file_list_templ and len(dumps_num_list) > 1 and
            '%s' not in file_list_templ):
        usage("In order to write more than one output file with"
              " dump runs, the value specified for dirlisting must"
              " contain '%s' which will be replaced by the number"
              " of dumps to write to the given output file")

    config = WikiConfig(configfile)
    dlist = DumpList(config, dumps_num_list, relative, rsynclists,
                     dir_list_templ, file_list_templ, output_dir,
                     projects_url, top_level)
    dlist.load_projectlist()
    dlist.gen_dumpfile_dirlists()


if __name__ == "__main__":
    do_main()
