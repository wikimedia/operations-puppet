#!/usr/bin/python3

import argparse
import datetime
import ipaddress
import os
import re
import subprocess
import sys

# nagios return codes
OK = 0
WARNING = 1
CRITICAL = 2
UNKNOWN = 3

DEFAULT_BACKUP_JOB_CONFIG_PATH = '/etc/bacula/jobs.d'
BCONSOLE_PATH = "/usr/sbin/bconsole"

# We believe no nested patterns are allowed, so a regex should be good enough
JOB_PATTERN = r'\s*Job\s*\{\s*([^\}]*)\s*\}\s*'
OPTION_PATTERN = r'\s*([^\=]+)\s*=\s*\"?([^\"\n]+)\"?\s*'
STATUS_COLUMNS_PATTERN = r'\s*\|\s+([^\|]+)'


def read_configuration_file(path):
    """
    Open path parameter file for reading and parse its job configuration,
    return a list of dictionaries containing its basic options
    """
    try:
        with open(path, 'r') as file:
            data = file.read()
    except EnvironmentError:
        print('ERROR: File "{}" could not be open for reading'.format(path))
        sys.exit(UNKNOWN)

    match = re.findall(JOB_PATTERN, data)
    jobs = list()
    for job in match:
        jobs.append(re.findall(OPTION_PATTERN, job))

    backups = dict()
    for job in jobs:
        job_properties = {'job_type': 'backup',  # set default/allowed keys and values
                          'name': None,
                          'client': None,  # note client is normally a fqdn + '-fd'
                          'schedule': None,
                          'fileset': None}
        for option in job:
            key = option[0].strip().lower()
            value = option[1].strip()
            if key == 'type':  # handle special case Type
                job_properties['job_type'] = value.lower()
            elif key == 'jobdefs':  # handle special case JobDefs
                job_properties['schedule'] = value
            elif key in job_properties.keys():  # TODO: Should we detect duplicates?
                job_properties[key] = value
        if job_properties['job_type'] != 'backup' or job_properties['name'] is None:
            continue
        backups[job_properties['name']] = job_properties
    return backups


def read_configured_backups(path):
    """
    Read the config files on given directory path and return the jobs
    that are backups in an array of dictionaries
    """
    try:
        files = os.listdir(path)
    except FileNotFoundError:  # noqa: F821
        print('ERROR: Path "{}" does not exist'.format(path))
        sys.exit(UNKNOWN)
    backups = dict()
    for f in files:
        config_file = os.path.join(path, f)
        if os.path.isfile(config_file):  # skip directories
            backups.update(read_configuration_file(config_file))
    return backups


def get_job_statuses(name, bconsole_path):
    """
    Given a job name, execute bconsole (with configurable bconsole_path)
    and obtain the list of execution attempts and its result, as dictionaries
    """
    cmd = [bconsole_path]
    process = subprocess.Popen(cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                               stderr=subprocess.PIPE)
    out, err = process.communicate(input='list jobname={}'.format(name).encode('utf8'))
    if process.returncode > 0 or err.decode('utf8') != '':
        print('ERROR: Run of bconsole failed: {}'.format(err.decode('utf8')))
        sys.exit(UNKNOWN)
    lines = out.decode('utf8').splitlines()
    # Parse output of bconsole ascii boxes, line by line, including the header
    statuses = list()
    header = None
    for line in lines:
        if line.startswith('|'):  # header or backup job
            if header is None:
                header = [h.strip().lower() for h in re.findall(STATUS_COLUMNS_PATTERN, line)]
            else:
                cols = [c.strip() for c in re.findall(STATUS_COLUMNS_PATTERN, line)]
                statuses.append(dict(zip(header, cols)))
    return statuses


def add_job_statuses(backups, bconsole_path):
    """
    Mutates the given dictionary, adding the statuses of each job
    alongside the original dictionary
    """
    for name, options in backups.items():
        backups[name]['status'] = get_job_statuses(name, bconsole_path)


def iso_date_to_datetime(string):
    """
    Converts and iso date string into a datetime object
    """
    return datetime.datetime.strptime(string, '%Y-%m-%d %H:%M:%S')


def older(timestamp, interval_in_seconds):
    """
    Returns true if given timestamp is older than the given time interval in seconds,
    false otherwise
    """
    return timestamp < datetime.datetime.now() - datetime.timedelta(seconds=interval_in_seconds)


def get_expected_freshness(schedule):
    """
    Given a schedule (actually, a JobDefs name, which on Wikimedia
    always start with Hourly, Weekly or Monthly), provide a pair of
    expected fresnhess of any backup, and full backups, in seconds
    TODO: Make thresholds configurable and less arbitrary
    """
    if schedule.startswith('Hourly'):
        # Full weekly, incremental hourly
        expected_freshness = 3 * 3600
        expected_full_freshness = 8 * 24 * 3600
    elif schedule.startswith('Weekly'):
        # Only fulls, weekly
        expected_freshness = 8 * 24 * 3600
        expected_full_freshness = 8 * 24 * 3600
    else:  # We assume Monthly
        # Fulls monthly, diffs every other fortnite, incr. daily
        expected_freshness = 2 * 24 * 3600
        expected_full_freshness = 32 * 24 * 3600
    return expected_freshness, expected_full_freshness


def get_dates_of_last_good_backups(status):
    """
    Return a pair of datetime objects, the first with the timedelta
    of the execution of the latest good backup (incremental, differential or
    full), the second with the time of the latest good full backup.
    If both type, or full backup only cannot be found from the list of good
    ones, it will return None
    """
    latest_good_backup = None
    latest_full_good_backup = None

    # search the latest and latest full good backups date (by doing it in
    # reverse order)
    for i in range(len(status) - 1, -1, -1):
        job = status[i]
        if job['jobstatus'] == 'T' and latest_good_backup is None:
            latest_good_backup = iso_date_to_datetime(job['starttime'])
        if job['level'] == 'F' and job['jobstatus'] == 'T' and job['jobbytes'] != '0':
            latest_full_good_backup = iso_date_to_datetime(job['starttime'])
            break
    return latest_good_backup, latest_full_good_backup


def first_hostname(backup_list):
    """
    For printing purposes only, given a list of backup status, return the first
    client, by simplify the string representing a host (normally an ip or fqdn)
    and return the simplest identifying part (hostname)
    """
    # Hosts were not read in order, for stability of output, always return the
    # first one alphabetically
    host = min(backup_list, key=lambda k: k['client'])
    try:  # Is the host an IP? Then don't try to output a hostname or it will print "127"
        ipaddress.ip_address(host['client'])
        return host['client']
    except ValueError:
        return host['client'].split('.')[0]


def check_backup_freshness(status):
    """
    Classifies the backup freshness, for each configured job
    on bacula default path on 5 categories:
    * Jobs with correct expected fresh backups
    * Jobs with stale full backups (they are older than expected)
    * Jobs with stale incrementals/differentials
    * Jobs with all failed backups
    * Jobs where no backups have been attempted/scheduled
    """
    jobs_with_fresh_backups = list()
    jobs_with_stale_full_backups = list()
    jobs_with_stale_backups = list()
    jobs_with_all_failures = list()
    jobs_with_no_backups = list()
    for backup_name in status:
        if len(status[backup_name]['status']) == 0:
            # There are not past backup attempts, skip all other processing
            jobs_with_no_backups.append(status[backup_name])
            continue

        latest_good_backup, latest_full_good_backup = get_dates_of_last_good_backups(
            status[backup_name]['status'])
        if latest_full_good_backup is None:
            jobs_with_all_failures.append(status[backup_name])
            continue

        expected_freshness, expected_full_freshness = get_expected_freshness(
            status[backup_name]['schedule'])

        if older(latest_good_backup, expected_freshness):
            jobs_with_stale_backups.append(status[backup_name])
        elif older(latest_full_good_backup, expected_full_freshness):
            jobs_with_stale_full_backups.append(status[backup_name])
        else:
            jobs_with_fresh_backups.append(status[backup_name])

    return {'jobs_with_all_failures': jobs_with_all_failures,
            'jobs_with_stale_backups': jobs_with_stale_backups,
            'jobs_with_stale_full_backups': jobs_with_stale_full_backups,
            'jobs_with_no_backups': jobs_with_no_backups,
            'jobs_with_fresh_backups': jobs_with_fresh_backups}


def print_icinga_jobs(msg, level, returncode, cats, index, name, show_examples=True):
    """
    Given an existing error message, append to it the one
    for this index dictionary key on cats categories, with
    the given name. If show examples is true, also append one example host.
    It also sets retun code with the given level if there are members.
    Return the amended message and the new return code (or the input
    one if it was not modified).
    """
    if len(cats[index]) > 0:
        if not show_examples:
            msg.append('{}: {}'.format(name, len(cats[index])))
        elif len(cats[index]) == 1:
            msg.append('{}: {} ({})'.format(name,
                                            len(cats[index]),
                                            first_hostname(cats[index])))
        else:
            msg.append('{}: {} ({}, ...)'.format(name,
                                                 len(cats[index]),
                                                 first_hostname(cats[index])))
        returncode = level if returncode < level else returncode

    return msg, returncode


def print_icinga_status(categories):
    """
    Print status in icinga style and exit with the appropiate error code
    """
    totaljobs = sum(len(v) for v in categories.values())
    if totaljobs == 0:
        print('UNKNOWN: No backups configured')
        sys.exit(UNKNOWN)

    msg = list()
    returncode = OK

    level = CRITICAL
    msg, returncode = print_icinga_jobs(msg, level, returncode, categories,
                                        'jobs_with_all_failures', 'All failures')
    msg, returncode = print_icinga_jobs(msg, level, returncode, categories,
                                        'jobs_with_stale_backups', 'Stale')
    msg, returncode = print_icinga_jobs(msg, level, returncode, categories,
                                        'jobs_with_stale_full_backups', 'Stale-full only')

    level = WARNING
    msg, returncode = print_icinga_jobs(msg, level, returncode, categories,
                                        'jobs_with_no_backups', 'No backups')

    level = OK
    msg, returncode = print_icinga_jobs(msg, level, returncode, categories,
                                        'jobs_with_fresh_backups', 'Fresh', show_examples=False)

    print(', '.join(msg) + ' jobs')
    sys.exit(returncode)


def print_verbose_status(categories):
    """
    Prints the full list of jobs that failed and were successful.
    """
    for category in sorted(categories):
        print("\n== " + category + ' (' + str(len(categories[category])) + ") ==\n")
        for job in sorted(categories[category], key=lambda k: k['name']):
            print(job['name'])


def print_job_status(job, bconsole_path):
    """
    Prints the list of job executions for a given job, or an error
    message if the job doesn't have attempts
    """
    statuses = get_job_statuses(job, bconsole_path)
    if len(statuses) == 0:
        print('No jobs found for {}'.format(job))
        sys.exit(-1)
    for status in statuses:
        print('{}: type: {}, status: {}, bytes: {}'.format(status['starttime'],
                                                           status['level'],
                                                           status['jobstatus'],
                                                           status['jobbytes']))


def calculate_success_rate(backups, from_seconds_ago, to_seconds_ago):
    """
    This (right now) unused method allow an easy way to calculate the
    rate of successful backups (attempted vs. terminated correctly)
    withing a period, as defined between now() - from_seconds_ago and
    now() - to_seconds_ago.
    For example, to calculate the success rate in the last week, call:
    calculate_succes_rate(backups_with_status, 7 * 24 * 3600, 0)
    """
    successful = 0
    failures = 0
    for backup_name in backups:
        for job in backups[backup_name]['status']:
            if (older(iso_date_to_datetime(job['starttime']), from_seconds_ago)
                    or not older(iso_date_to_datetime(job['starttime']), to_seconds_ago)):
                continue
            # success conditions for full backups
            if job['level'] == 'F':
                if job['jobstatus'] == 'T' and job['jobbytes'] != '0':
                    successful += 1
                else:
                    failures += 1
            # success conditions for non-full backups
            elif job['jobstatus'] == 'T':
                successful += 1
            else:
                failures += 1
    print('Successful jobs in the given period = {}'.format(successful))
    print('Failed jobs in the given period = {}'.format(failures))
    success_percentage = str(round(successful * 100.0 / (successful + failures), 2)) + '%'
    print('Percentage of success = successful * 100 / (failed + successful) = {}'
          .format(success_percentage))


def read_options():
    """
    Handle command line execution arguments
    """
    parser = argparse.ArgumentParser(
        description=('Checks bacula backup freshness status and prints it on standard output.')
    )

    parser.add_argument('job',
                        default=None,
                        nargs='?',
                        help=('If set, check only the status of this job. '
                              'Otherwise, check all jobs.'))
    parser.add_argument('--verbose',
                        action='store_true',
                        help=('If set, it prints the full list of jobs in its categories. '
                              'Otherwise, it prints just a summary for icinga.'))
    parser.add_argument('--backup_config_path',
                        default=DEFAULT_BACKUP_JOB_CONFIG_PATH,
                        help=('Path of the directory with the files where the bacula job '
                              'configuration is, by default: "{}".'
                              '').format(DEFAULT_BACKUP_JOB_CONFIG_PATH))
    parser.add_argument('--bconsole_path',
                        default=BCONSOLE_PATH,
                        help=('Full path of the "bconsole" executable, by default: "{}".'
                              '').format(BCONSOLE_PATH))

    options = parser.parse_args()
    return options


def main():
    options = read_options()
    if options.job:
        # Mode: check single job
        print_job_status(options.job, options.bconsole_path)
    else:
        backups = read_configured_backups(options.backup_config_path)
        add_job_statuses(backups, options.bconsole_path)
        # TODO: calculate_success_rate(backups, 7 * 24 * 3600, 0)
        categories = check_backup_freshness(backups)
        if options.verbose:
            # Mode: verbose (for console)
            print_verbose_status(categories)
        else:
            # Mode: summary (for icinga)
            print_icinga_status(categories)
    # TODO: check_device_status()


if __name__ == "__main__":
    main()
