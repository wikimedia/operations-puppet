#!/usr/bin/python3
import argparse
import datetime
import os
import re
import signal
import subprocess
import sys
import time
from prometheus_client.core import GaugeMetricFamily, REGISTRY, CounterMetricFamily
from prometheus_client import start_http_server

DEFAULT_PORT = 9133  # http port to listen to

# nagios return codes
OK = 0
WARNING = 1
CRITICAL = 2
UNKNOWN = 3

DEFAULT_JOB_CONFIG_PATH = '/etc/bacula/jobs.d'
DEFAULT_BCONSOLE_PATH = '/usr/sbin/bconsole'
JOB_PATTERN = r'\s*Job\s*\{\s*([^\}]*)\s*\}\s*'
OPTION_PATTERN = r'\s*([^\=]+)\s*=\s*\"?([^\"\n]+)\"?\s*'


class Bacula(object):

    def __init__(self, config_path=DEFAULT_JOB_CONFIG_PATH,
                 bconsole_path=DEFAULT_BCONSOLE_PATH):
        self.config_path = config_path
        self.bconsole_path = bconsole_path
        self.backups = None

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
        else:  # We assume Monthly
            # Fulls monthly, diffs every other fortnite, incr. daily
            return 2 * 24 * 3600, 32 * 24 * 3600

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
            if job_properties['job_type'] != 'backup' or job_properties['name'] is None:
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
        return executions

    def add_job_executions(self):
        """
        Mutates the given dictionary, adding the statuses of each job
        alongside the original dictionary
        """
        for name, options in self.backups.items():
            self.backups[name]['executions'] = self.get_job_executions(name)

    def get_dates_of_last_good_backups(self, executions):
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
        for i in range(len(executions) - 1, -1, -1):
            execution = executions[i]
            if (execution['type'] == 'B' and execution['jobstatus'] == 'T' and
                    latest_good_backup is None):
                latest_good_backup = execution['endtime']
            if (execution['type'] == 'B' and execution['level'] == 'F' and
                    execution['jobstatus'] == 'T' and execution['jobbytes'] != '0'):
                latest_full_good_backup = execution['endtime']
                break
        return latest_good_backup, latest_full_good_backup

    def older(self, timestamp, interval_in_seconds):
        """
        Returns true if given timestamp is older than the given time interval in seconds,
        false otherwise
        """
        return (timestamp <= datetime.datetime.now() -
                datetime.timedelta(seconds=interval_in_seconds))

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
            executions = bacula.backups[job]['executions']
            latest_good_backup, latest_good_full_backup = bacula.get_dates_of_last_good_backups(
                executions)
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
        bacula = Bacula()
        bacula.read_configured_backups()
        bacula.add_job_executions()
        yield from self.get_good_backup_dates(bacula)  # noqa: E999
        yield from self.get_last_executed_job_metrics(bacula)  # noqa: E999
        yield from self.get_expected_freshness(bacula)  # noqa: E999
        yield from self.get_success_rate(bacula)  # noqa: E999


def sigint(sig, frame):
    """
    Exit cleanly when a sigint signal is received.
    """
    print('SIGINT received by the process', file=sys.stderr)
    sys.exit(0)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--port', '-P', type=int,
                        help='the port the http server will be listening on',
                        default=DEFAULT_PORT)
    options = parser.parse_args()

    signal.signal(signal.SIGINT, sigint)
    start_http_server(options.port)
    REGISTRY.register(BaculaCollector())
    while True:
        time.sleep(1)


if __name__ == "__main__":
    main()
