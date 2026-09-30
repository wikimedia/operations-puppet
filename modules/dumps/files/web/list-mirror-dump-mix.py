#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
"""
generate rsync inclusion lists for the mirror modules, where the v2
content exports replace the deprecated v1 files of each xml/sql dump
run with a date on or after a cutoff date
"""
import functools
import getopt
import os
import re
import sys
import time


#############################################################
# This file is maintained by puppet!
# puppet:///modules/dumps/web/list-mirror-dump-mix.py
#############################################################


V2_DATASETS = ['mediawiki_content_history', 'mediawiki_content_current']
V2_COMPRESSIONS = ['bzip2', '7z']
MANIFEST = 'SHA256SUMS'
# v1 dump files that the v2 content exports replace
DEPRECATED_V1 = re.compile(
    r'-(stub-meta-history|stub-meta-current|stub-articles|pages-meta-current|pages-meta-history)')
V1_LINE = re.compile(r'^/([^/]+)/([0-9]{8})(/.*)?$')
CUTOFF = re.compile(r'^[0-9]{4}-[0-9]{2}-[0-9]{2}$')


class MixError(Exception):
    """for things that should never happen while generating the lists"""


@functools.lru_cache(maxsize=None)
def is_complete(dirpath, settle_secs):
    """
    return True if the directory has a manifest, all files in the manifest
    are present, and no file changed in the last settle_secs seconds
    """
    try:
        with open(os.path.join(dirpath, MANIFEST), 'r') as fdesc:
            listed = [line.split()[-1] for line in fdesc if line.strip()]
        entries = os.listdir(dirpath)
        if not listed or not set(listed).issubset(entries):
            return False
        # a file that the fetch job still writes has a recent ctime
        newest = max(os.stat(os.path.join(dirpath, name)).st_ctime for name in entries)
        return newest < time.time() - settle_secs
    except OSError:
        return False


def v2_date(date):
    """convert yyyymmdd to yyyy-mm-dd"""
    return '-'.join([date[0:4], date[4:6], date[6:8]])


def get_replaced_runs(lines, cutoff, v2wikis):
    """
    return the set of (wiki, yyyymmdd) of the v1 runs in the lines on or
    after the cutoff, for the wikis in v2wikis
    """
    runs = set()
    for line in lines:
        match = V1_LINE.match(line)
        if (match and not match.group(3) and match.group(1) in v2wikis
                and v2_date(match.group(2)) >= cutoff):
            runs.add((match.group(1), match.group(2)))
    return runs


def get_v2_wikis(dumpsdir, v2dir):
    """return the set of wikis with a v2 directory. v2 does not export closed wikis."""
    wikis = set()
    for dataset in V2_DATASETS:
        try:
            wikis.update(os.listdir(os.path.join(dumpsdir, v2dir, dataset)))
        except OSError:
            pass
    return wikis


def mix_v1_lines(lines, replaced, dumpsdir):
    """
    return the v1 rsync inclusion lines, without the deprecated
    files of the runs in replaced, a set of (wiki, yyyymmdd)
    """
    mixed = []
    for line in lines:
        match = V1_LINE.match(line)
        if not match or (match.group(1), match.group(2)) not in replaced:
            mixed.append(line)
        elif match.group(3) == '/*':
            # list the files of the run one by one, since a wildcard would include all of them
            rundir = os.path.join(dumpsdir, match.group(1), match.group(2))
            try:
                names = sorted(os.listdir(rundir))
            except OSError:
                continue
            if not any(DEPRECATED_V1.search(name) for name in names):
                # nothing to leave out, for example after the v1 sunset
                mixed.append(line)
                continue
            mixed.extend(line[:-1] + name for name in names
                         if os.path.isfile(os.path.join(rundir, name))
                         and not DEPRECATED_V1.search(name))
        elif not (match.group(3) and DEPRECATED_V1.search(match.group(3))):
            mixed.append(line)
    return mixed


def get_v2_lines(replaced, dumpsdir, v2dir, settle_secs):
    """
    return the rsync inclusion lines for the complete v2 output of the
    runs in replaced. each dataset and compression is included on its own
    when it is complete.
    """
    top = '/' + v2dir.strip(os.sep)
    lines = []
    wikidirs = set()
    for wiki, date in sorted(replaced):
        for dataset in V2_DATASETS:
            wikidir = '/'.join([top, dataset, wiki])
            rundir = wikidir + '/' + v2_date(date)
            comps = [comp for comp in V2_COMPRESSIONS
                     if is_complete(os.path.join(dumpsdir, rundir.lstrip('/'), 'xml', comp),
                                    settle_secs)]
            if comps:
                # the daemon hides all of other/, so each dir on the path needs its own line
                if wikidir not in wikidirs:
                    wikidirs.add(wikidir)
                    lines.append(wikidir)
                lines.extend([rundir, rundir + '/xml'])
                lines.extend(rundir + '/xml/' + comp + '/***' for comp in comps)
    if not lines:
        return []
    return ([top] + [top + '/' + dataset for dataset in V2_DATASETS]
            + [top + '/' + dataset + '/readme.html' for dataset in V2_DATASETS] + lines)


def write_list(path, lines):
    """write the lines to path, and keep the previous file as path.old"""
    with open(path + '.tmp', 'w') as fdesc:
        fdesc.write('\n'.join(lines) + '\n')
    if os.path.exists(path):
        os.rename(path, path + '.old')
    os.rename(path + '.tmp', path)


def usage(message=None):
    """display usage message, call when we encounter an options error"""
    if message:
        sys.stderr.write(message + "\n\n")
    usage_message = """Usage: python3 list-mirror-dump-mix.py --dumpsdir <path> --cutoff yyyy-mm-dd
                --v1list filename-format --output filename-format
                [--dumpsnumber n[,n...]] [--v2dir <path>] [--settle minutes]

Options:

dumpsdir    -- directory under which public dumps of all wikis reside
               default value: none
cutoff      -- for each v1 run with a date on or after this date, the output
               list has the v2 run with the same date in place of the
               deprecated v1 files. the v2 files are included when they are
               complete. v1 runs before this date, and v1 runs of wikis with
               no v2 directory, do not change.
               default value: none
v1list      -- name format of the v1 rsync inclusion lists in dumpsdir, with
               '%s' for n; list-last-n-good-dumps.py writes these lists
               default value: none
output      -- name format of the output lists in dumpsdir, with '%s' for n
               default value: none
dumpsnumber -- comma-separated list of n, one output list for each
               default value: 5
v2dir       -- directory of the v2 content exports, relative to dumpsdir
               default value: other
settle      -- a v2 directory with a file that changed in the last so many
               minutes is not complete
               default value: 180

Example use:
python3 list-mirror-dump-mix.py --dumpsdir /data/xmldatadumps/public
               --cutoff 2026-11-01 --dumpsnumber 1,5
               --v1list rsync-inc-last-%s.txt --output rsync-inc-mix-%s.txt
"""
    sys.stderr.write(usage_message)
    sys.exit(1)


def do_main():
    """main entry point. parse options, write one mixed list per n"""
    dumpsdir = None
    cutoff = None
    v1list = None
    output = None
    dumps_num = '5'
    v2dir = 'other'
    settle = '180'

    try:
        (options, remainder) = getopt.gnu_getopt(
            sys.argv[1:], "", ['dumpsdir=', 'cutoff=', 'v1list=', 'output=', 'dumpsnumber=',
                               'v2dir=', 'settle='])
    except getopt.GetoptError:
        usage("Unknown option specified")
    if remainder:
        usage("Unknown option specified: %s" % remainder[0])

    for (opt, val) in options:
        if opt == '--dumpsdir':
            dumpsdir = val.rstrip(os.sep)
        elif opt == '--cutoff':
            cutoff = val
        elif opt == '--v1list':
            v1list = val
        elif opt == '--output':
            output = val
        elif opt == '--dumpsnumber':
            dumps_num = val
        elif opt == '--v2dir':
            v2dir = val
        elif opt == '--settle':
            settle = val

    if not dumpsdir or not cutoff or not v1list or not output:
        usage("dumpsdir, cutoff, v1list and output must be specified")
    if not CUTOFF.match(cutoff):
        usage("cutoff must be a date in the format yyyy-mm-dd")
    if '%s' not in v1list or '%s' not in output:
        usage("v1list and output must contain '%s'")
    dumps_num_list = [num.strip() for num in dumps_num.split(',')]
    if not all(num.isdigit() and int(num) > 0 for num in dumps_num_list):
        usage("dumpsnumber must be a comma-separated list of numbers greater than 0")
    if not settle.isdigit():
        usage("settle must be a number of minutes")

    v2wikis = get_v2_wikis(dumpsdir, v2dir)
    for num in dumps_num_list:
        v1path = os.path.join(dumpsdir, v1list % num)
        if not os.path.exists(v1path):
            raise MixError("No v1 list %s. Run list-last-n-good-dumps.py first." % v1path)
        with open(v1path, 'r') as fdesc:
            v1lines = [line.rstrip('\n') for line in fdesc if line.strip()]
        replaced = get_replaced_runs(v1lines, cutoff, v2wikis)
        write_list(os.path.join(dumpsdir, output % num),
                   mix_v1_lines(v1lines, replaced, dumpsdir)
                   + get_v2_lines(replaced, dumpsdir, v2dir, int(settle) * 60))


if __name__ == "__main__":
    do_main()
