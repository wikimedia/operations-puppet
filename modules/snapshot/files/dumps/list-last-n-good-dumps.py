import os
import re
import urllib
import sys
import getopt
import ConfigParser
from subprocess import Popen, PIPE
from os.path import exists, isdir


class DumpListError(Exception):
    pass


class WikiConfig(object):

    def __init__(self, ConfigFile):
        home = os.path.dirname(sys.argv[0])
        self.files = [
            os.path.join(home, configFile),
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
        self.publicDir = self.conf.get("output", "public")
        self.tempDir = self.conf.get("output", "temp")
        self.dbList = sorted(filter(None, [db.strip() for db in open(
            self.conf.get("wiki", "dblist")).readlines()]))


class DumpList(object):
    """This class generates a list of the last n sets of XML
    dump files per project that were successful, adding failed
    and/or incomplete dumps to the list if there are not n
    successful dumps available; n varies across a specified
    list of numbers of dumps desired, and the corresponding
    lists are produced for all dumps in one pass."""

    def __init__(self, config, dumpsNumberList, relative,
                 rsynclists, dirListTemplate, fileListTemplate,
                 outputDir, projectsUrl, topLevel):
        """constructor; besides the obvious, sets up the list of
        filetypes we want to include in our list, see
        self.filesWantedPattern"""

        self.config = config
        self.dumpsNumberList = dumpsNumberList
        self.maxDnum = max(self.dumpsNumberList)
        self.relative = relative
        self.rsynclists = rsynclists
        self.dirListTemplate = dirListTemplate
        self.fileListTemplate = fileListTemplate
        self.outputDir = outputDir
        if self.outputDir and self.outputDir.endswith(os.sep):
            self.outputDir = self.outputDir[:-1 * len(os.sep)]
        self.filesWantedPattern = re.compile(
            '(\.gz|\.bz2|\.7z|\.html|\.txt|\.xml)$')
        self.ymdPattern = re.compile('^2[0-1][0-9]{6}$')
        self.projectsUrl = projectsUrl
        self.topLevel = topLevel

    def getProjectListFromUrlOrConfig(self):
        """try to retrieve the list of known projects from a specified
        url; if there was no url given, try contents read from the filename
        given for 'dblist' in the config file"""
        contents = ""
        if self.projectsUrl:
            try:
                # e.g. http://noc.wikimedia.org/conf/all.dblist
                infd = urllib.urlopen(self.projectsUrl)
                self.contents = infd.read()
                infd.close()
            except:
                sys.stderr.write("Warning: Failed to retrieve project"
                                 " list via http, using old list\n")

        elif self.config.dbList:
            try:
                contents = '\n'.join(self.config.dbList) + '\n'
            except:
                sys.stderr.write("Warning: Failed to retrieve good"
                                 " project list from %s as specified"
                                 " in config file, using old list\n"
                                 % self.config.dbList)

        return contents

    def getTempDir(self):
        """returns the full path to a directory for temporary files"""
        tempdir = self.config.tempDir
        if not tempdir:
            tempdir = self.getAbsOutDir('tmp')
        return tempdir

    def getProjectListCopyFileName(self):
        """returns name we use for the local copy of the project list"""
        return "all.dblist"

    def getProjectListFromOldFile(self):
        """We try to save a temp copy of the list of known projects
        on every run; retrieve that copy"""

        contents = ""

        tempdir = self.getTempDir()
        dblist = os.path.join(tempdir, self.getProjectListCopyFileName())

        # read previous contents, if any...
        try:
            infd = open(dblist, "r")
            contents = infd.read()
            infd.close()
        except:
            sys.stderr.write("Warning: Old project list %s from"
                             " previous run is unavailable\n" % dblist)
        return contents

    def saveProjectList(self, contents):
        """save local copy of the project list we presumably
        retrieved from elsewhere"""
        tempdir = self.getTempDir()
        dblist = os.path.join(tempdir, self.getProjectListCopyFileName())

        try:
            # ok it passes the smell test (or we filled it with
            # the old contents), save this as the new list
            if not exists(tempdir):
                os.makedirs(tempdir)
            outfd = open(dblist, "wt")
            outfd.write(self.contents)
            outfd.close()
        except:
            # we can still do our work so don't die, but do complain
            sys.stderr.write("Warning: Failed to save project list"
                             " to file %s\n" % dblist)

    def loadProjectList(self):
        """Get and store the list of all projects known to us; this
        includes closed projects but may not include all projects
        that ever existed, for example tlhwik."""

        self.projects = []
        oldContents = self.getProjectListFromOldFile()
        if len(oldContents):
            oldProjects = oldContents.splitlines()
        else:
            oldProjects = []

        self.contents = self.getProjectListFromUrlOrConfig()
        if len(self.contents):
            self.projects = self.contents.splitlines()
        else:
            self.projects = []

        # check that this list is not comlete crap compared to the
        # previous list, if any, before we get started. arbitrarily:
        # a change of more than 5% in size
        if (len(oldProjects) and
                float(len(self.projects)) / float(len(oldProjects)) < .95):
            sys.stderr.write("Warning: New list of projects is much"
                             " smaller than previous run, %s"
                             " compared to %s\n" % (len(self.projects),
                                                    len(oldProjects)))
            sys.stderr.write("Warning: Using old list; remove old list"
                             " %s to override\n"
                             % os.path.join(self.getTempDir(),
                                            self.getProjectListCopyFileName()))

            self.projects = oldProjects
            self.contents = oldContents

        if not len(self.projects):
            raise DumpListError("List of projects is empty, giving up")

        self.saveProjectList(self.contents)

    def getAbsPubDirPath(self, name):
        """return full path to the location of public dumps,
        as specified in the config file for the entry 'publicdir'"""
        return os.path.join(self.config.publicDir, name)

    def getAbsOutDirPath(self, name):
        """return full path to the location where output files will
        be written"""
        if self.outputDir:
            return os.path.join(self.outputDir, name)
        else:
            return os.path.join(self.config.publicDir, name)

    def getDirStatus(self, dirToCheck, day):
        if isdir(os.path.join(dirToCheck, day)):
            try:
                statusFile = os.path.join(dirToCheck, day, "status.html")
                fd = open(statusFile, "r")
                text = fd.read()
                fd.close()
            except:
                # if there is no status file, the dir could have any
                # kind of random junk in it so don't risk it
                return None
            return text
        return None

    def getFirstDir(self, dirs, dirToCheck):
        if not dirs:
            return False
        for day in dirs:
            text = self.getDirStatus(dirToCheck, day)
            if text is None:
                continue
            if "failed" not in text:
                return day

        # no dump in there that's not failed. meh.
        # try again and take the first one we can read
        for day in dirs:
            text = self.getDirStatus(dirToCheck, day)
            if text is None:
                continue
            return day

        # no dumps with status we can read. give up
        return False

    def listDumpsForProject(self, project):
        """get list of dump directories for a given project
        ordered by good dumps first, most recent to oldest, then
        failed dumps most rcent to oldest, and finally incomplete
        dumps most recent to oldest"""
        dirToCheck = self.getAbsPubDirPath(project)
        if not exists(dirToCheck):
            return []

        dirs = os.listdir(dirToCheck)
        # dirs have the format yyyymmdd and we want only those and
        # listed most recent first by date, not by ctime or mtime.
        dirs = [d for d in dirs if self.ymdPattern.search(d)]
        dirs.sort()
        dirs.reverse()

        dirsFailed = []
        dirsComplete = []
        dirsOther = []

        dirsReported = []

        dirFirst = self.getFirstDir(dirs, dirToCheck)
        if not dirFirst:
            # never dumped
            return dirsReported

        for day in dirs:
            if day == dirFirst:
                continue
            text = self.getDirStatus(dirToCheck, day)
            if text is None:
                continue

            if "failed" in text:
                dirsFailed.append(day)
            elif "Dump complete" in text:
                dirsComplete.append(day)
            else:
                dirsOther.append(day)

        dirsReported.append(dirFirst)
        dirsReported.extend(dirsComplete)
        dirsReported.extend(dirsOther)
        dirsReported.extend(dirsFailed)
        return dirsReported

    def listFileTemplates(self):
        """list the templates for filenames that were provided
        by the caller, i.e. the template for the lists of files of
        the last n dumps, and the template for the lists of dirs
        of the last n dumps"""
        filenameTempls = []
        filenameTempls.extend(filter(None, [self.dirListTemplate,
                                            self.fileListTemplate]))
        return filenameTempls

    def fillInFilenameTemplate(self, templ, number):
        """given a filename template which expects to have a number
        plugged into it someplace (indicated by a '%s'), make
        the substitution and return the new name"""
        if '%s' in templ:
            return templ % number
        else:
            return templ

    def getFileNamesFromDir(self, dirName):
        """given a dump directory (the full path to a specific run),
        get the names of the files we want to list; we only pick
        up the files that are part of the public run, not scratch or other
        files, and the filenames are either full paths or are relative
        to the base directory of the public dumps, depending on
        user-specified options."""
        filesWanted = []
        if self.fileListTemplate:
            dirContents = os.listdir(dirName)
            filesWanted = ([os.path.join(dirName, f) for f in dirContents
                           if self.filesWantedPattern.search(f)])
            if self.relative:
                filesWanted = [self.stripPublicDir(f) for f in filesWanted]
        return filesWanted

    def truncateOutputFiles(self):
        """call this once at the beginning of any run to truncate
        all output files before beginning to write to them"""
        filenameTempls = self.listFileTemplates()
        for t in filenameTempls:
            for n in self.dumpsNumberList:
                f = self.fillInFilenameTemplate(t, n)
                try:
                    fd = open(self.getAbsOutDirPath(f + ".tmp"), "wt")
                    fd.close()
                except:
                    pass

    def writeFileNames(self, num, dirName, fileNamesToWrite,
                       skipDirs=False):
        """write supplied list of filenames from the project dump
        of a particular run into files named as specified by the
        user, and write the project dump directory name into
        separate files named as specified by the user"""
        if self.fileListTemplate:
            outputFileName = self.getAbsOutDirPath(
                self.fillInFilenameTemplate(
                    self.fileListTemplate, num) + ".tmp")
            filesfd = open(outputFileName, "a")
            filesfd.write('\n'.join(fileNamesToWrite))
            filesfd.write('\n')
            filesfd.close()
        if self.dirListTemplate and not skipDirs:
            outputFileName = self.getAbsOutDirPath(
                self.fillInFilenameTemplate(
                    self.dirListTemplate, num) + ".tmp")
            if self.relative:
                dirName = self.stripPublicDir(dirName)
            dirsfd = open(outputFileName, "a")
            dirsfd.write(dirName + '\n')
            dirsfd.close()

    def writeFileAndDirListsForProject(self, project):
        """for a given project, write all dirs and all files from
        the last n dumps to various files with n varying as
        specified by the user"""
        dirs = self.listDumpsForProject(project)
        fileNamesToWrite = None
        index = 0
        projectPath = self.getAbsPubDirPath(project)
        while index < len(dirs):
            if index >= self.maxDnum:
                break
            if self.fileListTemplate:
                fileNamesToWrite = self.getFileNamesFromDir(os.path.join(
                    projectPath, dirs[index]))
            for dn in self.dumpsNumberList:
                if index < int(dn):
                    self.writeFileNames(dn, os.path.join(
                        projectPath, dirs[index]), fileNamesToWrite)
            index = index + 1

    def stripPublicDir(self, line):
        """remove the path to the public dumps directory from
        the beginning of the suppplied line, if it exists"""
        if line.startswith(self.config.publicDir + os.sep):
            line = line[len(self.config.publicDir):]
        return line

    def convertFileNamesForRsyncInput(self, f):
        """prep list of filenames so that it can be passed
        to rsync --list-only"""

        # to make this work we have to feed it a file with the filenames
        # with the publicdir stripped off the front, if it's there
        fpath = self.getAbsOutDirPath(f)
        infd = open(fpath, "r")
        outfd = open(fpath + ".relpath",  "w")
        lines = infd.readlines()
        infd.close()
        for line in lines:
            if not self.relative:
                outfd.write(self.stripPublicDir(line))
            else:
                outfd.write(line)
        outfd.close()

    def doRsyncListOnly(self, f):
        """produce long listing of files from a specific dump run,
        by passing the file list to rsync --list-only"""
        fpath = self.getAbsOutDirPath(f)
        command = ["/usr/bin/rsync", "--list-only", "--no-h",
                   "--files-from", fpath + ".relpath",
                   self.config.publicDir,
                   "dummy", ">", fpath + ".rsync"]
        commandString = " ".join(command)
        proc = Popen(commandString, shell=True, stderr=PIPE)
        # output will be None, we can ignore it
        output, error = proc.communicate()
        if proc.returncode:
            raise DumpListError(
                "command '" + commandString +
                ("' failed with return code %s " % proc.returncode) +
                " and error '" + error + "'")

    def getTopLevelFiles(self):
        # list *html and *txt files in top level dir
        # test, with "" does this work?
        filesInDir = [f for f in os.listdir(self.getAbsPubDirPath(""))
                      if f.endswith(".html") or f.endswith(".txt")]
        return filesInDir

    def writeTopLevelFiles(self):
        """write the html and txt files in the top level dirextory to
        the appropriate output files."""
        fileNamesToWrite = self.getTopLevelFiles()
        for dn in self.dumpsNumberList:
            self.writeFileNames(dn, None, fileNamesToWrite, skipDirs=True)

    def generateDumpFileAndDirLists(self):
        """produce all files of dir lists and file lists from
        all desired dump runs for all projects"""
        self.truncateOutputFiles()
        if self.topLevel:
            self.writeTopLevelFiles()
        for p in self.projects:
            self.writeFileAndDirListsForProject(p)

        filenameTempls = self.listFileTemplates()
        for t in filenameTempls:
            for n in self.dumpsNumberList:
                f = self.fillInFilenameTemplate(t, n)
                # do this last so that if someone is using the file
                # in the meantime, they  aren't interrupted
                fpath = self.getAbsOutDirPath(f)
                if exists(fpath + ".tmp"):
                    if exists(fpath):
                        os.rename(fpath, fpath + ".old")
                    os.rename(fpath + ".tmp", fpath)
                else:
                    raise DumpListError("No output file %s created. "
                                        "Something is wrong." % fpath + ".tmp")

                if self.rsynclists:
                    self.convertFileNamesForRsyncInput(f)
                    self.doRsyncListOnly(f)


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

if __name__ == "__main__":
    configFile = "wikidump.conf"
    dumpsNumber = "5"
    relative = False
    rsynclists = False
    topLevel = False
    dirListTemplate = None
    fileListTemplate = None
    projectsUrl = None
    outputDir = None

    try:
        (options, remainder) = getopt.gnu_getopt(
            sys.argv[1:], "", ['configfile=', 'dumpsnumber=',
                               'outputdir=', 'projectlisturl=',
                               'relpath', 'rsynclists',
                               'toplevel', 'dirlisting=',
                               'filelisting='])
    except:
        usage("Unknown option specified")

    if len(remainder):
        usage("Unknown option specified: %s", remainder)

    for (opt, val) in options:
        if opt == "--configfile":
            configFile = val
        elif opt == "projectlisturl":
            projectsUrl = val
        elif opt == '--dumpsnumber':
            dumpsNumber = val
        elif opt == '--outputdir':
            outputDir = val
        elif opt == '--relpath':
            relative = True
        elif opt == '--rsynclists':
            rsynclists = True
        elif opt == "--dirlisting":
            dirListTemplate = val
        elif opt == "--filelisting":
            fileListTemplate = val
        elif opt == "--toplevel":
            topLevel = True

    if ',' not in dumpsNumber:
        dumpsNumberList = [dumpsNumber.strip()]
    else:
        dumpsNumberList = [d.strip() for d in dumpsNumber.split(',')]

    for d in dumpsNumberList:
        if not d.isdigit() or not int(d):
            usage("dumpsnumber must be a number or a comma-separated"
                  " list of numbers each greater than 0")

    if not dirListTemplate and not fileListTemplate:
        usage("At least one of --dirlisting or"
              " --filelisting must be specified")

    if (fileListTemplate and len(dumpsNumberList) > 1 and
            '%s' not in fileListTemplate):
        usage("In order to write more than one output file with"
              " dump runs, the value specified for filelisting"
              " must contain '%s' which will be replaced by the"
              " number of dumps to write to the given output file")

    if (fileListTemplate and len(dumpsNumberList) > 1 and
            '%s' not in fileListTemplate):
        usage("In order to write more than one output file with"
              " dump runs, the value specified for dirlisting must"
              " contain '%s' which will be replaced by the number"
              " of dumps to write to the given output file")

    config = WikiConfig(configFile)
    dl = DumpList(config, dumpsNumberList, relative, rsynclists,
                  dirListTemplate, fileListTemplate, outputDir,
                  projectsUrl, topLevel)
    dl.loadProjectList()
    dl.generateDumpFileAndDirLists()
