#!/usr/bin/python3
import argparse
import datetime
import ipaddress
from multiprocessing import Pool
import os
import re
import signal
import subprocess
import sys
import time
from prometheus_client.core import GaugeMetricFamily, REGISTRY
from prometheus_client import start_http_server

DEFAULT_PORT = 9133  # http port to listen to

# nagios return codes
OK = 0
WARNING = 1
CRITICAL = 2
UNKNOWN = 3

DEFAULT_JOB_CONFIG_PATH = '/etc/bacula/jobs.d'
DEFAULT_BCONSOLE_PATH = '/usr/sbin/bconsole'
DEFAULT_PARALLEL_THREADS = 4
JOB_PATTERN = r'\s*Job\s*\{\s*([^\}]*)\s*\}\s*'
OPTION_PATTERN = r'\s*([^\=]+)\s*=\s*\"?([^\"\n]+)\"?\s*'
DEFAULT_JOB_MONITORING_IGNORELIST = '/etc/bacula/job_monitoring_ignorelist'


class Bacula(object):

    def __init__(self, config_path=DEFAULT_JOB_CONFIG_PATH,
                 bconsole_path=DEFAULT_BCONSOLE_PATH,
                 parallel_threads=DEFAULT_PARALLEL_THREADS,
                 ignorelist_path=DEFAULT_JOB_MONITORING_IGNORELIST):
        self.config_path = config_path
        self.bconsole_path = bconsole_path
        self.parallel_threads = parallel_threads
        self.ignorelist_path = ignorelist_path
        self.backups = None
        self.categories = None
        self.ignorelist = list()

    def get_expected_freshness(self, schedule):
        """
        Given a schedule (actually, a JobDefs name, which on Wikimedia
        always start with Hourly, Weekly or Monthly), provide a pair of
        expected fresnhess of any backup, and full backups, in seconds
        TODO: Make thresholds configurable and/or not WMF-specific
        """
        if schedule.startswith('Hourly'):
            # Full weekly, incremental hourly
            return 3 * 3600, 8 * 24 * 3600
        elif schedule.startswith('Weekly'):
            # Only fulls, weekly
            return 8 * 24 * 3600, 8 * 24 * 3600
        elif schedule.startswith('Daily'):
            # Only fulls, daily
            return 2 * 24 * 3600, 2 * 24 * 3600
        else:  # We assume Monthly
            # Fulls monthly, diffs every other fortnite, incr. daily
            return 2 * 24 * 3600, 36 * 24 * 3600

    def read_configuration_file(self, path):
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
                    expected_freshness, expected_full_freshness = self.get_expected_freshness(value)
                    job_properties['expected_freshness'] = expected_freshness
                    job_properties['expected_full_freshness'] = expected_full_freshness
                elif key in job_properties.keys():  # TODO: Should we detect duplicates?
                    job_properties[key] = value
            # ignore non-backups and badly configured jobs
            if job_properties['job_type'] != 'backup' or job_properties['name'] is None:
                continue
            # ignore manual list of jobs to skip
            if job_properties['name'] in self.ignorelist:
                continue
            backups[job_properties['name']] = job_properties
        return backups

    def read_configured_backups(self):
        """
        Read the config files on given directory path and return the jobs
        that are backups in an array of dictionaries
        """
        try:
            files = os.listdir(self.config_path)
        except FileNotFoundError:  # noqa: F821
            print('ERROR: Path "{}" does not exist'.format(self.config_path))
            sys.exit(UNKNOWN)
        self.backups = dict()
        for f in files:
            config_file = os.path.join(self.config_path, f)
            if os.path.isfile(config_file):  # skip directories
                self.backups.update(self.read_configuration_file(config_file))

    def read_ignorelist(self):
        """
        Tries to read the list of ignored jobs for monitoring and store it on memory
        """
        try:
            with open(self.ignorelist_path, 'r') as file:
                lines = file.read().splitlines()
            # ignore empty lines and comments
            self.ignorelist = [i.strip() for i in lines
                               if i.strip() and not i.strip().startswith('#')]
        except Exception:
            pass

    def format_bacula_value(self, value, key):
        """
        Returns value of type key in the appropiate format
        """
        # integers with commas
        if key in ['jobid', 'purgedfiles', 'clientid', 'jobtdate', 'volsessionid',
                   'volsessiontime', 'jobfiles', 'jobbytes', 'readbytes', 'joberrors',
                   'jobmissingfiles', 'poolid', 'priorjobid', 'filesetid']:
            return int(value.replace(',', ''))
        # dates
        if key in ['schedtime', 'starttime', 'endtime', 'realendtime']:
            if value in ['0000-00-00 00:00:00', 'NULL']:
                return None
            return datetime.datetime.strptime(value, '%Y-%m-%d %H:%M:%S')
        # bools
        if key in ['hasbase', 'hascache']:
            return bool(value)
        return value

    def get_job_executions(self, name):
        """
        Given a job name, execute bconsole (with configurable bconsole_path)
        and obtain the list of execution attempts and its result, as dictionaries
        """
        cmd = [self.bconsole_path]
        process = subprocess.Popen(cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                                   stderr=subprocess.PIPE)
        out, err = process.communicate(input='llist jobname={}'.format(name).encode('utf8'))
        if process.returncode > 0 or err.decode('utf8') != '':
            print('ERROR: Run of bconsole failed: {}'.format(err.decode('utf8')))
            sys.exit(UNKNOWN)
        lines = out.decode('utf8').splitlines()

        executions = list()
        i = 0
        length = len(lines)
        while i < length:
            # garbage content, skip
            while i < length and not lines[i].lstrip().startswith('JobId:'):
                i += 1
            execution = dict()
            # interesting fields
            while i < length and lines[i].strip() != '':
                fields = lines[i].split(':', 1)
                key = fields[0].strip().lower()
                execution[key] = self.format_bacula_value(fields[1].strip(), key)
                i += 1
            if 'type' in execution and execution['type'] == 'B' and 'name' in execution:
                executions.append(execution)
        return {'name': name, 'executions': executions}

    def add_job_result(self, result):
        self.backups[result['name']]['executions'] = result['executions']

    def add_job_executions(self):
        """
        Adds a list of the executions, in id order, of each job in the backups,
        with the dictionary key 'executions'
        """
        pool = Pool(processes=self.parallel_threads)
        for name in self.backups:
            pool.apply_async(self.get_job_executions, args=(name,), callback=self.add_job_result)
        pool.close()
        pool.join()

    def get_dates_of_last_good_backups(self, job):
        """
        Return a pair of datetime objects, the first with the timedelta
        of the execution of the latest good backup (incremental, differential or
        full), the second with the time of the latest good full backup.
        If both type, or full backup only cannot be found from the list of good
        ones, it will return None
        """
        latest_good_backup = None
        latest_full_good_backup = None

        if job not in self.backups:
            return None, None
        executions = self.backups[job]['executions']
        # search the latest and latest full good backups date (by doing it in
        # reverse order)
        for i in range(len(executions) - 1, -1, -1):
            execution = executions[i]
            if (execution['type'] == 'B' and execution['jobstatus'] == 'T'
                    and latest_good_backup is None):
                latest_good_backup = execution['endtime']
            if (execution['type'] == 'B' and execution['level'] == 'F'
                    and execution['jobstatus'] == 'T' and execution['jobbytes'] != '0'):
                latest_full_good_backup = execution['endtime']
                break
        return latest_good_backup, latest_full_good_backup

    def older(self, timestamp, interval_in_seconds):
        """
        Returns true if given timestamp is older than the given time interval in seconds,
        false otherwise
        """
        return (timestamp <= datetime.datetime.now()
                - datetime.timedelta(seconds=interval_in_seconds))

    def calculate_success_rate(self, from_seconds_ago, to_seconds_ago):
        """
        Returns the total number of backups, and the total number of successful
        backups in the given period [now() - from_seconds_ago, now() - to_seconds_ago]
        from_seconds_ago is expected to be larger than to_seconds_ago.
        """
        successful = 0
        failures = 0
        for job in self.backups:
            executions = self.backups[job]['executions']
            for i in range(len(executions) - 1, -1, -1):
                execution = executions[i]
                if execution['starttime'] is None:
                    continue
                if self.older(execution['starttime'], from_seconds_ago):
                    break
                if not self.older(execution['starttime'], to_seconds_ago):
                    continue
                # success conditions for full backups
                if execution['level'] == 'F':
                    if execution['jobstatus'] == 'T' and execution['jobbytes'] > 0:
                        successful += 1
                    else:
                        failures += 1
                # success conditions for non-full backups
                elif execution['jobstatus'] == 'T':
                    successful += 1
                else:
                    failures += 1
        return successful + failures, successful

    def print_job_list(self):
        if not len(self.backups):
            print('No configured jobs found.')
            sys.exit(-1)
        for job in sorted(self.backups):
            print(job)

    def print_job_status(self, job):
        """
        Prints the list of job executions for a given job, or an error
        message if the job doesn't have attempts
        """
        result = self.get_job_executions(job)
        if len(result['executions']) == 0:
            print('No jobs found for {}'.format(job))
            sys.exit(-1)
        for status in result['executions']:
            print('{}: type: {}, status: {}, bytes: {}'
                  ''.format(status['starttime'],
                            status['level'],
                            status['jobstatus'],
                            status['jobbytes']))

    def check_backup_freshness(self):
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
        for backup_name in self.backups:
            job = self.backups[backup_name]
            if len(job['executions']) == 0:
                # There are not past backup attempts, skip all other processing
                jobs_with_no_backups.append(job)
                continue

            (latest_good_backup,
             latest_full_good_backup) = self.get_dates_of_last_good_backups(backup_name)
            if latest_full_good_backup is None:
                jobs_with_all_failures.append(job)
                continue

            expected_freshness, expected_full_freshness = self.get_expected_freshness(
                job['schedule'])

            if self.older(latest_good_backup, expected_freshness):
                jobs_with_stale_backups.append(job)
            elif self.older(latest_full_good_backup, expected_full_freshness):
                jobs_with_stale_full_backups.append(job)
            else:
                jobs_with_fresh_backups.append(job)

        self.categories = {
            'jobs_with_all_failures': jobs_with_all_failures,
            'jobs_with_stale_backups': jobs_with_stale_backups,
            'jobs_with_stale_full_backups': jobs_with_stale_full_backups,
            'jobs_with_no_backups': jobs_with_no_backups,
            'jobs_with_fresh_backups': jobs_with_fresh_backups}

    def first_hostname(self, backup_list):
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

    def print_icinga_jobs(self, msg, level, returncode, cats, index, name, show_examples=True):
        """
        Given an existing error message, append to it the one
        for this index dictionary key on cats categories, with
        the given name. If show examples is true, also append one example host.
        It also sets return code with the given level if there are members.
        Return the amended message and the new return code (or the input
        one if it was not modified).
        """
        if len(cats[index]) > 0:
            if not show_examples:
                msg.append('{}: {}'.format(name, len(cats[index])))
            elif len(cats[index]) == 1:
                msg.append('{}: {} ({})'.format(name,
                                                len(cats[index]),
                                                self.first_hostname(cats[index])))
            else:
                msg.append('{}: {} ({}, ...)'.format(name,
                                                     len(cats[index]),
                                                     self.first_hostname(cats[index])))
            returncode = level if returncode < level else returncode

        return msg, returncode

    def print_icinga_status(self):
        """
        Print status in icinga style and exit with the appropiate error code
        """
        totaljobs = sum(len(v) for v in self.categories.values())
        if totaljobs == 0:
            print('UNKNOWN: No backups configured')
            sys.exit(UNKNOWN)

        msg = list()
        returncode = OK

        level = CRITICAL
        msg, returncode = self.print_icinga_jobs(msg, level, returncode, self.categories,
                                                 'jobs_with_all_failures', 'All failures')
        msg, returncode = self.print_icinga_jobs(msg, level, returncode, self.categories,
                                                 'jobs_with_stale_backups', 'Stale')
        msg, returncode = self.print_icinga_jobs(msg, level, returncode, self.categories,
                                                 'jobs_with_stale_full_backups', 'Stale-full only')

        level = WARNING
        msg, returncode = self.print_icinga_jobs(msg, level, returncode, self.categories,
                                                 'jobs_with_no_backups', 'No backups')

        level = OK
        msg, returncode = self.print_icinga_jobs(msg, level, returncode, self.categories,
                                                 'jobs_with_fresh_backups', 'Fresh',
                                                 show_examples=False)

        print(', '.join(msg) + ' jobs')
        sys.exit(returncode)

    def print_verbose_status(self):
        """
        Prints the full list of jobs that failed and were successful.
        """
        for category in sorted(self.categories):
            print("\n== " + category + ' (' + str(len(self.categories[category])) + ") ==\n")
            for job in sorted(self.categories[category], key=lambda k: k['name']):
                print(job['name'])


class BaculaCollector(object):
    """
    Class that retrieves and returns metrics for a bacula instance
    """
    def __init__(self, config_path=DEFAULT_JOB_CONFIG_PATH,
                 bconsole_path=DEFAULT_BCONSOLE_PATH):
        """
        Initialization
        """
        self.bconsole_path = bconsole_path
        self.config_path = config_path

    def get_good_backup_dates(self, bacula):
        """
        For each job, return the dates of the last successful backup, and the last
        successful full backup.
        """
        for job in bacula.backups:
            latest_good_backup, latest_good_full_backup = bacula.get_dates_of_last_good_backups(job)
            g = GaugeMetricFamily('bacula_job_last_good_backup',
                                  'Timestamp of the latest good backup for a given job',
                                  labels=['bacula_job'])
            g.add_metric([job], latest_good_backup.timestamp()
                         if latest_good_backup is not None else 0)
            yield g
            g = GaugeMetricFamily('bacula_job_last_good_full_backup',
                                  'Timestamp of the latest good full backup for a given job',
                                  labels=['bacula_job'])
            g.add_metric([job], latest_good_full_backup.timestamp()
                         if latest_good_full_backup is not None else 0)
            yield g

    def get_last_executed_job_metrics(self, bacula):
        """
        For each job, if they have at least one execution, return the metrics of the last
        execution.
        """
        for job in bacula.backups:
            executions = bacula.backups[job]['executions']
            if len(executions) == 0:
                continue
            last_execution = executions[-1]
            g = GaugeMetricFamily('bacula_job_last_execution_job_id',
                                  'Job Id of the last job execution',
                                  labels=['bacula_job'])
            g.add_metric([job], last_execution['jobid'])
            yield g
            g = GaugeMetricFamily('bacula_job_last_execution_purged_files',
                                  'Purged files of the last job execution',
                                  labels=['bacula_job'])
            g.add_metric([job], last_execution['purgedfiles'])
            yield g
            g = GaugeMetricFamily('bacula_job_last_execution_type',
                                  'Type of the last job execution (ord("B") for backup, etc.)',
                                  labels=['bacula_job'])
            g.add_metric([job], ord(last_execution['type']))
            yield g
            g = GaugeMetricFamily('bacula_job_last_execution_level',
                                  ('Level of the last job execution '
                                   '(ord("F") for full backup, etc.)'),
                                  labels=['bacula_job'])
            g.add_metric([job], ord(last_execution['level']))
            yield g
            g = GaugeMetricFamily('bacula_job_last_execution_job_status',
                                  ('Job Status of the last job execution '
                                   '(ord("T") for successful, etc.)'),
                                  labels=['bacula_job'])
            g.add_metric([job], ord(last_execution['jobstatus']))
            yield g
            g = GaugeMetricFamily('bacula_job_last_execution_sched_time',
                                  'Scheduled time of the last job execution timestamp',
                                  labels=['bacula_job'])
            g.add_metric([job], last_execution['schedtime'].timestamp()
                         if last_execution['schedtime'] is not None else 0)
            yield g
            g = GaugeMetricFamily('bacula_job_last_execution_start_time',
                                  'Start time of the last job execution timestamp',
                                  labels=['bacula_job'])
            g.add_metric([job], last_execution['starttime'].timestamp()
                         if last_execution['starttime'] is not None else 0)
            yield g
            g = GaugeMetricFamily('bacula_job_last_execution_end_time',
                                  'End time of the last job execution timestamp',
                                  labels=['bacula_job'])
            g.add_metric([job], last_execution['endtime'].timestamp()
                         if last_execution['endtime'] is not None else 0)
            yield g
            g = GaugeMetricFamily('bacula_job_last_execution_real_end_time',
                                  'Real end time of the last job execution timestamp',
                                  labels=['bacula_job'])
            g.add_metric([job], last_execution['realendtime'].timestamp()
                         if last_execution['realendtime'] is not None else 0)
            yield g
            g = GaugeMetricFamily('bacula_job_last_execution_job_files',
                                  'Number of files processed on the last job execution',
                                  labels=['bacula_job'])
            g.add_metric([job], last_execution['jobfiles'])
            yield g
            g = GaugeMetricFamily('bacula_job_last_execution_job_bytes',
                                  'Total bytes processed on the last job execution',
                                  labels=['bacula_job'])
            g.add_metric([job], last_execution['jobbytes'])
            yield g
            g = GaugeMetricFamily('bacula_job_last_execution_read_bytes',
                                  'Total bytes read on the last job execution',
                                  labels=['bacula_job'])
            g.add_metric([job], last_execution['readbytes'])
            yield g
            g = GaugeMetricFamily('bacula_job_last_execution_job_errors',
                                  'Job errors found on the last job execution',
                                  labels=['bacula_job'])
            g.add_metric([job], last_execution['joberrors'])
            yield g
            g = GaugeMetricFamily('bacula_job_last_execution_job_missing_files',
                                  'Job missing files on the last job execution',
                                  labels=['bacula_job'])
            g.add_metric([job], last_execution['jobmissingfiles'])
            yield g
            g = GaugeMetricFamily('bacula_job_last_execution_pool_id',
                                  'Pool Id used on the last job execution',
                                  labels=['bacula_job'])
            g.add_metric([job], last_execution['poolid'])
            yield g
            g = GaugeMetricFamily('bacula_job_last_execution_file_set_id',
                                  'File Set Id used on the last job execution',
                                  labels=['bacula_job'])
            g.add_metric([job], last_execution['filesetid'])
            yield g

    def get_expected_freshness(self, bacula):
        """
        Returns metrics related to expected backup freshness
        """
        for job in bacula.backups:
            g = GaugeMetricFamily('bacula_job_expected_freshness_seconds',
                                  ('Maximum amount of time (in seconds) that '
                                   'should pass between backups for this job'),
                                  labels=['bacula_job'])
            g.add_metric([job], bacula.backups[job]['expected_freshness'])
            yield g
            g = GaugeMetricFamily('bacula_job_expected_full_freshness_seconds',
                                  ('Maximum amount of time (in seconds) that '
                                   'should pass between full backups for this job'),
                                  labels=['bacula_job'])
            g.add_metric([job], bacula.backups[job]['expected_full_freshness'])
            yield g

    def get_success_rate(self, bacula):
        """
        Provide metrics regarding total count and succesful count of attempted backup
        jobs in the last week
        """
        # last month
        total, succesful = bacula.calculate_success_rate(from_seconds_ago=30 * 24 * 3600,
                                                         to_seconds_ago=0)
        g = GaugeMetricFamily('bacula_backups_last_month',
                              'Number of backups attempted in the last month')
        g.add_metric([], total)
        yield g
        g = GaugeMetricFamily('bacula_backups_last_month_successful',
                              'Number of succesful backups completed in the last month')
        g.add_metric([], succesful)
        yield g

        # last week
        total, succesful = bacula.calculate_success_rate(from_seconds_ago=7 * 24 * 3600,
                                                         to_seconds_ago=0)
        g = GaugeMetricFamily('bacula_backups_last_week',
                              'Number of backups attempted in the last week')
        g.add_metric([], total)
        yield g
        g = GaugeMetricFamily('bacula_backups_last_week_successful',
                              'Number of succesful backups completed in the last week')
        g.add_metric([], succesful)
        yield g

        # last day
        total, succesful = bacula.calculate_success_rate(from_seconds_ago=24 * 3600,
                                                         to_seconds_ago=0)
        g = GaugeMetricFamily('bacula_backups_last_day',
                              'Number of backups attempted in the last day')
        g.add_metric([], total)
        yield g
        g = GaugeMetricFamily('bacula_backups_last_day_successful',
                              'Number of succesful backups completed in the last day')
        g.add_metric([], succesful)
        yield g

    def collect(self):
        """
        Gather metrics
        """
        bacula = Bacula(self.bconsole_path, self.config_path)
        bacula.read_ignorelist()
        bacula.read_configured_backups()
        bacula.add_job_executions()
        yield from self.get_good_backup_dates(bacula)  # noqa: E999
        yield from self.get_last_executed_job_metrics(bacula)  # noqa: E999
        yield from self.get_expected_freshness(bacula)  # noqa: E999
        yield from self.get_success_rate(bacula)  # noqa: E999


def read_options():
    """
    Handle command line execution arguments
    """
    parser = argparse.ArgumentParser(
        description=('Checks bacula backup freshness status and prints it on standard '
                     'output (or starts the bacula prometheus exporter).')
    )

    parser.add_argument('job',
                        default=None,
                        nargs='?',
                        help=('If set, check only the status of this job. '
                              'Otherwise, check all jobs.'))
    parser.add_argument('--list-jobs',
                        action='store_true',
                        help=('When used, it just prints the list of configured '
                              'backup jobs and returns without any check.'))

    parser.add_argument('--prometheus',
                        action='store_true',
                        default=None,
                        help=('If set, instead of outputing information to the command '
                              'line, it waits in a loop listening for an HTTP request '
                              'and returns metrics in the typical prometheus exporter format.'))
    parser.add_argument('--port',
                        type=int,
                        default=DEFAULT_PORT,
                        help=('When using the prometheus mode, it binds and listends '
                              'on this port. If no one is given, {} is used by default.'
                              ''.format(DEFAULT_PORT)))
    parser.add_argument('--icinga',
                        action='store_true',
                        help=('If set, it prints just a summary for icinga. Otherwise, '
                              'it prints a detailed output to the command line.'))
    parser.add_argument('--backup_config_path',
                        default=DEFAULT_JOB_CONFIG_PATH,
                        help=('Path of the directory with the files where the bacula job '
                              'configuration is, by default: "{}".'
                              '').format(DEFAULT_JOB_CONFIG_PATH))
    parser.add_argument('--bconsole_path',
                        default=DEFAULT_BCONSOLE_PATH,
                        help=('Full path of the "bconsole" executable, by default: "{}".'
                              '').format(DEFAULT_BCONSOLE_PATH))

    options = parser.parse_args()
    return options


def sigint(sig, frame):
    """
    Exit cleanly when a sigint signal is received.
    """
    print('SIGINT received by the process', file=sys.stderr)
    sys.exit(0)


def bacula_prometheus_exporter_listen(options):
    """
    Wait and listen to http connections to request metrics
    """
    signal.signal(signal.SIGINT, sigint)
    start_http_server(options.port)
    REGISTRY.register(BaculaCollector(options.bconsole_path, options.backup_config_path))
    while True:
        time.sleep(1)


def bacula_print_status(options):
    """
    Produce bacula status to the standards output, on different
    formats, depending on the options
    """
    bacula = Bacula(config_path=options.backup_config_path,
                    bconsole_path=options.bconsole_path)
    if options.job:
        # Mode: check single job
        bacula.print_job_status(options.job)
        sys.exit(0)

    if options.icinga:  # only ignore for icinga output
        bacula.read_ignorelist()
    bacula.read_configured_backups()

    if options.list_jobs:
        # Mode: list configured jobs
        bacula.print_job_list()
        sys.exit(0)

    bacula.add_job_executions()

    bacula.check_backup_freshness()
    if options.icinga:
        # Mode: summary (for icinga)
        bacula.print_icinga_status()
    else:
        # Mode: verbose (for console)
        bacula.print_verbose_status()
    # TODO: check_device_status()


def main():

    options = read_options()
    if options.prometheus:
        # Mode: prometheus exporter
        bacula_prometheus_exporter_listen(options)
    else:
        bacula_print_status(options)


if __name__ == "__main__":
    main()
