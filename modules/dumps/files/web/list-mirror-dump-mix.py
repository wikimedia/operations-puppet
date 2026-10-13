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
DEPRECATED_V1_TYPES = ['stub-meta-history', 'stub-meta-current', 'stub-articles',
                       'pages-meta-current', 'pages-meta-history']
DEPRECATED_V1 = re.compile('-(' + '|'.join(DEPRECATED_V1_TYPES) + ')')
V1_LINE = re.compile(r'^/(?P<wiki>[^/]+)/(?P<date>[0-9]{8})(?P<path>/.*)?$')
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


def get_runs(lines, cutoff):
    """
    return the set of (wiki, yyyymmdd) of the v1 runs in the lines on or
    after the cutoff
    """
    runs = set()
    for line in lines:
        match = V1_LINE.match(line)
        if match and not match['path'] and v2_date(match['date']) >= cutoff:
            runs.add((match['wiki'], match['date']))
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


def has_deprecated(dumpsdir, wiki, date):
    """return True if the v1 run directory has a deprecated file"""
    try:
        return any(DEPRECATED_V1.search(name)
                   for name in os.listdir(os.path.join(dumpsdir, wiki, date)))
    except OSError:
        return False


def get_v1_rules(lines, replaced, dumpsdir):
    """
    return the rules that leave out the deprecated files of the runs in
    replaced, a set of (wiki, yyyymmdd). they go before the v1 lines, since
    the first rule that matches a path wins. the rules match all wikis, so
    the v1 lines of the other runs of the same date go first, to keep them whole.
    after the v1 sunset, a date with no deprecated files gets no rules.
    """
    dates = sorted({date for wiki, date in replaced if has_deprecated(dumpsdir, wiki, date)})
    rules = []
    for date in dates:
        for line in lines:
            match = V1_LINE.match(line)
            if match and match['date'] == date and (match['wiki'], date) not in replaced:
                rules.append(line)
        rules.extend('- /*/%s/*-%s*' % (date, dtype) for dtype in DEPRECATED_V1_TYPES)
    return rules


def get_v2_lines(replaced, dumpsdir, v2dir, settle_secs):
    """
    return the rsync inclusion lines for the complete v2 output of the
    runs in replaced. each dataset and compression is included on its own
    when it is complete. when it is complete for all wikis, wildcards
    replace the lines for each wiki, since each line costs the rsync daemon
    time for each path it serves.
    """
    top = '/' + v2dir.strip(os.sep)
    lines = []
    for date in sorted({v2_date(rundate) for wiki, rundate in replaced}):
        wikis = sorted(wiki for wiki, rundate in replaced if v2_date(rundate) == date)
        for dataset in V2_DATASETS:
            datasetdir = os.path.join(dumpsdir, top.lstrip('/'), dataset)
            try:
                allwikis = os.listdir(datasetdir)
            except OSError:
                continue
            for comp in V2_COMPRESSIONS:
                # a wildcard also matches the wikis that are not in replaced, so check all of them
                compdirs = {wiki: os.path.join(datasetdir, wiki, date, 'xml', comp)
                            for wiki in allwikis}
                compdirs = {wiki: path for wiki, path in compdirs.items() if os.path.isdir(path)}
                if compdirs and all(is_complete(path, settle_secs) for path in compdirs.values()):
                    wikis_done = ['*']
                else:
                    wikis_done = [wiki for wiki in wikis
                                  if wiki in compdirs and is_complete(compdirs[wiki], settle_secs)]
                for wiki in wikis_done:
                    # the daemon hides all of other/, so each dir on the path needs its own line
                    rundir = '/'.join([top, dataset, wiki, date])
                    lines.extend(['/'.join([top, dataset, wiki]), rundir, rundir + '/xml',
                                  rundir + '/xml/' + comp + '/***'])
    if not lines:
        return []
    lines = ([top] + [top + '/' + dataset for dataset in V2_DATASETS]
             + [top + '/' + dataset + '/readme.html' for dataset in V2_DATASETS] + lines)
    # the same dir lines repeat for each compression
    return list(dict.fromkeys(lines))


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
        replaced = {(wiki, date) for wiki, date in get_runs(v1lines, cutoff) if wiki in v2wikis}
        write_list(os.path.join(dumpsdir, output % num),
                   get_v1_rules(v1lines, replaced, dumpsdir) + v1lines
                   + get_v2_lines(replaced, dumpsdir, v2dir, int(settle) * 60))


if __name__ == "__main__":
    do_main()
