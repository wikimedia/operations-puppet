"""
Given the root directory of wiki dumps, a directory with wiki
db lists, and a file with settings for how many dumps of a
wiki from each list we keep,
check each wiki dump directory to see if there are dumps than
 are desired, and remove the oldest one(s) if needed.
"""


import os
import sys
import getopt
import shutil
import re


def usage(message=None):
    '''
    display a helpful usage message with
    an optional introductory message first
    '''

    if message is not None:
        sys.stderr.write(message)
        sys.stderr.write("\n")
    usage_message = """
Usage: cleanup_old_xmldumps.py --keeps_conffile path --wikilists dir
           [--subdirs] [--help]

Given a directory with files with lists of wikis,
settings in a file describing how many dumps to keep
for wikis in each list, and the path of the directory
tree of the dumps, looks through each directory
treepath/wikiname/ to be sure that there are no more than
the specified number of dump directories. Dump directories
are subdirectories with the format YYYYMMDD; the rest are
ignored.
If there are more dump directories than specified, the
oldest ones will be removed.  Age is determined by
looking at the name of the directory, not atime/mtime/ctime.

Options:

  --dumpsdir   (-d):  path to root of dumps directory tree
  --keep       (-k):  path to config file describing how many
                      dumps per wiki we keep, for each file
                      containing a list of wikis
  --wiki       (-w):  wiki for which to dump config settings
  --subdirs    (-s):  directories in treepath must
                      match this expression in order to
                      be examined and cleaned up.
                      default: '*wik*'
  --help       (-h):  display this usage message

File formats:
   Wiki lists should have one wiki name per line, and this name
   should be the name of the wikis' dump directory in the dump
   tree.
   The keep config file should have one entry per line
   with the name of the wiki list file, a colon, and the number of
   dumps to keep.  Example: enwiki:3
   Note that blank lines or lines starting with '#' in both types
   of files will be skipped.
   An entry 'default:number' will be the value used for any wikis
   not in one of the specified lists.
Example:
  cleanup_old_xmldumps.py -k /etc/dumps/xml_keeps.conf \
           -d /mnt/dumpsdata/xmldatadumps/public -w /etc/dumps/dblists
"""
    sys.stderr.write(usage_message)
    sys.exit(1)


def get_wikilists(wikilists_dir):
    """
    read lists of wikis from files in a specified dir,
    skipping comments and blank lines, return dict of
    filenames and lists
    """
    wikilists = {}
    files = os.listdir(wikilists_dir)
    for filename in files:
        with open(os.path.join(wikilists_dir, filename), "r") as fhandle:
            lines = fhandle.readlines()
        wikilists[filename] = [line.strip() for line in lines if line and not line.startswith('#')]
    return wikilists


def get_allwikis(dumpsdir, match):
    """
    return list of all subdirectories of dumpsdir matching the
    supplied regular expression
    """
    subdirs = os.listdir(dumpsdir)
    return [subdir for subdir in subdirs
            if re.match(match, subdir) and os.path.isdir(os.path.join(dumpsdir, subdir))]


def get_keeps(keeps_conffile):
    """
    read a config file with one entry per line of format wikilist:numtokeep
    and return a dict.
    blank and comment lines are skipped, error messages will be diaplyed about
    badly formatted lines and they will be skipped but processing will continue.
    """
    keeps = {}
    with open(keeps_conffile, "r") as fhandle:
        lines = fhandle.readlines()
    for line in lines:
        if not line or line.startswith('#'):
            continue
        if ':' not in line:
            sys.stderr.write("Bad entry in keeps config file: " + line)
            continue
        listname, keepvalue = line.split(':', 1)
        keepvalue = keepvalue.strip()
        if not keepvalue.isdigit():
            sys.stderr.write("Bad entry in keeps config file, bad keeps value: " + line)
            continue
        keeps[listname] = keepvalue
    return keeps


class DumpsCleaner(object):
    """
    methods for finding and cleaning up old wiki dump dirs
    """
    def __init__(self, keeps_conffile, wikilists_dir, dumpsdir, wikipattern, dryrun):
        self.keeps_per_list = get_keeps(keeps_conffile)
        self.wikilists = get_wikilists(wikilists_dir)
        self.dumpsdir = dumpsdir
        self.wikistoclean = get_allwikis(self.dumpsdir, wikipattern)
        self.dryrun = dryrun

    def get_dumps(self, wiki):
        """
        get list of subdirs for dumpsdir/wiki/ in format YYYYDDMM
        all other subdirs are skipped.
        """
        path = os.path.join(self.dumpsdir, wiki)
        if not os.path.exists(path):
            return []
        dirs = os.listdir(path)
        return sorted([dirname for dirname in dirs if dirname.isdigit() and len(dirname) == 8])

    def get_keep_for_wiki(self, wiki):
        """
        find the keep value for the specified wiki
        by checking through the various keep conf settings,
        falling back to the default setting, if there is one
        if no setting is found, return None
        """
        for wikilist in self.wikilists:
            if wiki in wikilist:
                return self.keeps_per_list[wikilist]
        if 'default' in self.keeps_per_list:
            return self.keeps_per_list['default']
        return None

    def cleanup_dirs(self, wiki, dirs):
        """
        remove dumpsdir/wiki/dirname and all its contents
        for all the dirnames in the dirs list
        """
        for dirname in dirs:
            to_remove = os.path.join(self.dumpsdir, wiki, dirname)
            if self.dryrun:
                print "would remove ", to_remove
            else:
                shutil.rmtree("%s" % to_remove)

    def cleanup_wiki(self, keeps, wiki):
        """
        remove oldest dumps if we have more than the number to keep
        """
        dumps = self.get_dumps(wiki)
        if len(dumps) > int(keeps):
            self.cleanup_dirs(wiki, dumps[0:len(dumps) - int(keeps)])

    def clean(self):
        """
        remove oldest dumps from each wiki directory in dumpsdir
        if we are keeping too many, as determined by the conffile
        describing how many we keep for wikis in each list in the
        wikilists_dir, with optional default keep value.
        """
        for wiki in self.wikistoclean:
            tokeep = self.get_keep_for_wiki(wiki)
            if tokeep is None:
                continue
            self.cleanup_wiki(tokeep, wiki)


def check_args(args, remainder):
    """
    Whine about missing mandatory args, etc.
    """
    if len(remainder) > 0:
        usage("Unknown option(s) specified: <%s>" % remainder[0])

    for arg in args:
        if args[arg] is None:
            usage("Mandatory argument --{arg} not specified".format(arg=arg))


def main():
    'main entry point, does all the work'

    keeps_conffile = None
    dumpsdir = None
    subdirs = '*wik*'
    wikilists_dir = None
    dryrun = False

    try:
        (options, remainder) = getopt.gnu_getopt(
            sys.argv[1:], "d:k:s:w:Dh",
            ["dumpsdir=", "keep=", "subdirs=", "wikilists=", "dryrun", "help"])

    except getopt.GetoptError as err:
        usage("Unknown option specified: " + str(err))

    for (opt, val) in options:
        if opt in ["-d", "--dumpsdir"]:
            dumpsdir = val
        elif opt in ["-k", "--keep"]:
            keeps_conffile = val
        elif opt in ["-s", "--subdirs"]:
            subdirs = val
        elif opt in ["-w", "--wikilists"]:
            wikilists_dir = val
        elif opt in ["-D", "--dryrun"]:
            dryrun = True
        elif opt in ["-h", "--help"]:
            usage('Help for this script\n')
        else:
            usage("Unknown option specified: <%s>" % opt)

    check_args({'dumpsdir': dumpsdir, 'keep': keeps_conffile,
                'wikilists_dir': wikilists_dir}, remainder)

    if not os.path.exists(keeps_conffile):
        usage("no such file found: " + keeps_conffile)

    cleaner = DumpsCleaner(keeps_conffile, wikilists_dir, dumpsdir, subdirs, dryrun)
    cleaner.clean()


if __name__ == '__main__':
    main()
