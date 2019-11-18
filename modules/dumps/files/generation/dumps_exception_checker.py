#!/usr/bin/python3
'''
Given a rundate for the wikis dump run, the base dir for
private output from wiki dump runs, and the number of minutes
from the time this script is launched, look for any exceptions
in the time range of now to that number of minutes earlier,
in the dump logs, and print them out per wiki and in timestamp
order, with the stack traces.

Note that exceptions and their stack traces are expected to
start with Exception somewhere in the first line, and these
entries in the log are expected NOT to start with timestamps.

An exception and its stack trace is printed as one set of
entries, with a time stamp prepended only to the first line.

Note that since exceptions and errors are logged without a
timestamp, we assign them a timestamp based on the next entry
with a timestamp in the log (yeah ok not awesome but close
enough) or, if it's the last thing in the log, by the mtime
of the log file.
'''


import calendar
import os
import sys
import time
import re


IN_LOG = 0
IN_EXCEPTION = 1


def format_timestamp(timestamp):
    '''given a timestamp in format YYYY.MM.DD.HH.MM.SS where
    the . can be one of '-', ' ', ':', return just YYYYMMDDHHMMSS'''
    # 2019-08-01 11:07:57:
    return re.sub(':|-| ', '', timestamp)


def get_timestamp(line):
    '''given a log line, if there is a timestamp at the beginning,
    extract it, convert it to something useful, return it'''
    if not re.match('[0-9]{4}-', line):
        return None
    fields = line.split(' ')
    timestamp_unformatted = fields[0] + fields[1]
    if not timestamp_unformatted:
        return None
    timestamp = format_timestamp(timestamp_unformatted)
    if not timestamp.isdigit():
        return None
    if len(timestamp) != 14:
        return None
    return timestamp


def get_timestamp_from_mtime(path):
    '''given a path to a file, get the mtime, convert that
    to a timestamp in format YYYYMMDDHHMMSS and return it'''
    mtime = os.stat(path()).st_mtime
    return time.strftime("%Y%m%d%H%M%S", time.gmtime(mtime))


def safe_set(name, key, value):
    '''
    if the dict has the key already, concatenate the new
    value on the end of the old one
    otherwise set the new dict entry with the specified
    key and value
    '''
    if key in name:
        name[key] += value
    else:
        name[key] = value


def get_exceptions(dumplog, logpath):
    '''
    read and return all exceptions with their timestamps, and I guess
    this is all the stacktraces too, with a timestamp for each
    '''
    exceptions = {}
    timestamp = -1
    state = IN_LOG
    while True:
        line = re.sub(r' -p[^\s]*', ' -pXXXXX', dumplog.readline())
        if (line.startswith('Preparing') or line.startswith('getting/checking text')
           or line.startswith('Spawning database subprocess')):
            # ugh we have some junk lines in the log with no timestamp
            continue
        if not line:
            if -1 in exceptions:
                # if there's a stack trace last in the file, figure
                # out a plausible timestamp from the mtime of the log file
                timestamp = get_timestamp_from_mtime(logpath)
                safe_set(exceptions, timestamp, exceptions[-1])
                del exceptions[-1]
            return exceptions
        if state == IN_LOG:
            if not re.match('[0-9]{4}-', line):
                state = IN_EXCEPTION
                if line == '\n':
                    continue
                # if we have multiple log entries with the same time stamp
                # and multiple exceptions scattered among them, don't overwrite
                # the first error entry, just accumulate them
                safe_set(exceptions, timestamp, line)
        elif state == IN_EXCEPTION:
            if re.match('[0-9]{4}-', line):
                state = IN_LOG
                timestamp = get_timestamp(line)
                if -1 in exceptions:
                    exceptions[timestamp] = exceptions[-1]
                    del exceptions[-1]
            else:
                if line != '\n':
                    exceptions[timestamp] += line


def get_wikis_to_check(basedir, rundate):
    '''given the basedir, get and return the list of wikis to
    check for exception output in their logs
    '''
    wikis = os.listdir(basedir)
    to_return = []
    for wiki in wikis:
        if os.path.exists(os.path.join(basedir, wiki, rundate, 'dumplog.txt')):
            to_return.append(wiki)
    return to_return


def filter_exceptions(exceptions, start_time, end_time):
    '''given a start and end time in YYYYMMDDHHMMSS format,
    cull all of the exceptions out of there where the timestamps
    fall in the range, and return that smaller dict'''
    to_return = {}
    for timestamp in exceptions:
        if start_time <= timestamp <= end_time:
            to_return[timestamp] = exceptions[timestamp]
    return to_return


def display_wiki_exceptions(exceptions):
    '''given dict of exceptions per timestamp, display them in
    timestamp order'''
    for timestamp in sorted(exceptions.keys()):
        print('[' + timestamp + ']: ' + exceptions[timestamp])


def display_exception_info(exceptions):
    '''display the exceptions we have, with the wiki name and the
    timestamp'''
    if exceptions.keys():
        print("*******Wikis with exceptions:")
        print(', '.join(sorted(exceptions.keys())))
        print("===========================================================")
        print("")
    for wiki in sorted(exceptions.keys()):
        print("*** Wiki:", wiki)
        print("=====================")
        display_wiki_exceptions(exceptions[wiki])


def get_exceptions_for_wiki(wiki, basedir, start_time, end_time, rundate):
    '''
    for a given wiki, with the base directory specified, find all the exceptions
    in the dumplog.txt file for the wiki for the latest run, if any, and return
    the list
    '''
    logpath = os.path.join(basedir, wiki, rundate, 'dumplog.txt')
    with open(logpath, 'rt') as dumplog:
        exceptions = get_exceptions(dumplog, logpath)
        return filter_exceptions(exceptions, start_time, end_time)


def get_start_timestamp(end, interval):
    '''given a number of minutes and a starting timestamp in YYYYMMDDHHMMSS format,
    get start + interval minutes, and return it also in YYYYMMDDHHMMSS format'''
    # convert start_timestamp into seconds
    end_seconds = calendar.timegm(time.strptime(end, '%Y%m%d%H%M%S'))
    start_seconds = end_seconds - interval * 60
    return time.strftime("%Y%m%d%H%M%S", time.gmtime(start_seconds))


def usage(message=None):
    '''write a usage message to stderr and exit unhappily'''
    if message:
        sys.stderr.write(message + "\n")
    sys.stderr.write("Usage: dumps_exception_checker.py <basedir> <interval> <rundate>\n")
    sys.stderr.write("interval is the number of minutes from the rundate\n")
    sys.stderr.write("rundate is in YYYY-MM-DD format or 'latest'\n")
    sys.exit(1)


def validate_args(basedir, interval, rundate):
    '''sanity check of these args'''
    if not os.path.exists(basedir):
        usage("specified base dir <basedir> does not exist".format(basedir=basedir))
    if not interval.isdigit():
        usage("interval should be the number of minutes after the start time")
    if rundate == 'latest':
        return

    strawdawg_timestamp = format_timestamp(rundate)
    if not strawdawg_timestamp.isdigit() or len(strawdawg_timestamp) != 8:
        usage("bad timestamp, try YYYY-MM-DD or something like it")


def get_latest_rundate(basedir):
    '''
    given the base directory for private dump files, find the date for
    the latest run for any wiki and return it
    '''
    most_recent = "00000000"
    wikis = os.listdir(basedir)
    for wiki in wikis:
        subdirs = os.listdir(os.path.join(basedir, wiki))
        dates = sorted([subdir for subdir in subdirs if subdir.isdigit() and len(subdir) == 8])
        if dates and dates[-1] > most_recent:
            most_recent = dates[-1]
    return most_recent


def do_main():
    '''entry point'''
    if len(sys.argv) < 4:
        usage()

    basedir = sys.argv[1]
    interval = sys.argv[2]
    rundate = sys.argv[3]

    validate_args(basedir, interval, rundate)
    interval = int(interval)
    if rundate == 'latest':
        rundate = get_latest_rundate(basedir)
        if rundate is None:
            sys.stderr.write("No runs for any wiki ever started, do you have the right basedir?\n")
            sys.exit(1)

    end_timestamp = time.strftime("%Y%m%d%H%M%S", time.gmtime())

    wikis_to_check = get_wikis_to_check(basedir, rundate)
    if not wikis_to_check:
        sys.stderr.write("No wikis to check; did you specify the correct basedir?\n")
        sys.exit(1)

    exception_info = {}
    start_timestamp = get_start_timestamp(end_timestamp, interval)
    for wiki in wikis_to_check:
        output = get_exceptions_for_wiki(wiki, basedir, start_timestamp, end_timestamp, rundate)
        if output:
            exception_info[wiki] = output
    display_exception_info(exception_info)


if __name__ == '__main__':
    do_main()
