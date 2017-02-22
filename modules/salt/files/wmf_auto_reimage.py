#!/usr/bin/env python
"""Automated reimaging of a list of hosts"""

import argparse
import ConfigParser
import getpass
import json
import logging
import os
import re
import socket
import sys
import time

from datetime import datetime
from logging import FileHandler

import dns.resolver
import salt.client

from phabricator import Phabricator

ICINGA_DOMAIN = 'icinga.wikimedia.org'
PUPPET_DOMAIN = 'puppet.wikimedia.org'
DEPLOYMENT_DOMAIN = 'deployment.eqiad.wmnet'
INTERNAL_TLD = 'wmnet'
MANAGEMENT_DOMAIN = 'mgmt'

LOG_PATTERN = '/var/log/wmf-auto-reimage/{start}_{user}_{pid}.log'
# TODO: move it to a dedicated ops-orchestration-bot
PHABRICATOR_CONFIG_FILE = '/etc/phabricator_ops-monitoring-bot.conf'

PHAB_COMMENT_PRE = ('Script wmf_auto_reimage was launched by {user} on '
                    '{hostname} for hosts:\n```\n{hosts}\n```\n'
                    'The log can be found in `{log}`.')
PHAB_COMMENT_POST = 'Completed auto-reimage of hosts:\n```\n{hosts}\n```\n'
PHAB_COMMENT_POST_SUCCESS = 'and were **ALL** successful.\n'
PHAB_COMMENT_POST_FAILED = 'Of which those **FAILED**:\n```\n{failed}\n```\n'


WATCHER_SLEEP_THRESHOLD = 10  # Use the WATCHER_LONG_SLEEP after those loops
WATCHER_SHORT_SLEEP = 3  # Seconds to sleep between loops before the threshold
WATCHER_LONG_SLEEP = 60  # Seconds to sleep between loops after the threshold
WATCHER_LOG_LOOPS = 5  # Log progress after this number of long sleep loops

PHAB_TASK_PATTERN = re.compile('^T[0-9]+$')
HOSTS_PATTERN = re.compile('^[a-z0-9.-]+$')
CONFTOOL_SET_INACTIVE_PATTERN = ('^{host}: pooled changed (yes|no|inactive) '
                                 '=> inactive$')

logger = logging.getLogger('wmf_auto_reimage')


def parse_args():
    """ Parse and return command line arguments, validate the hosts"""

    parser = argparse.ArgumentParser(
        description='Automated reimaging of a list of hosts')
    parser.add_argument(
        '-d', '--debug', action='store_true', help='debug level logging')
    parser.add_argument(
        '--no-reboot', action='store_true',
        help='do not reboot the host after the reimage a first Puppet run')
    parser.add_argument(
        '--no-verify', action='store_true',
        help=('do not fail if hosts verification fails, just log it. Has no '
              'effect if --new is also set.'))
    parser.add_argument(
        '--new', action='store_true',
        help='for first imaging of new hosts, skip some steps on old hosts')
    parser.add_argument(
        '-c', '--conftool', action='store_true',
        help=('depool the host via conftool before proceeding, print the '
              'command to repool at the end and in the Phabricator task if -p '
              'is set. If --new is also set just print the pool message.'))
    parser.add_argument(
        '-a', '--apache', action='store_true',
        help='run apache-fast-test on the hosts after the reimage')
    parser.add_argument(
        '-p', '--phab-task-id', action='store',
        help='the Phabricator task ID (T12345)')
    parser.add_argument(
        'hosts', metavar='HOST', nargs='+', action='store',
        help='FQDN of the host(s) to be reimaged')

    args = parser.parse_args()

    # Perform a quick sanity check on the hosts
    for host in args.hosts:
        if '.' not in host or not HOSTS_PATTERN.match(host):
            raise ValueError("Expected FQDN of hosts, got '{host}'".format(
                host=host))

        if not is_hostname_valid(host):
            raise ValueError(
                "Unable to resolve host '{host}'".format(host=host))

    # Ensure there are no duplicates in the hosts list
    duplicates = {host for host in args.hosts if args.hosts.count(host) > 1}
    if len(duplicates) > 0:
        raise ValueError("Duplicate hosts detected: {dup}".format(
            dup=duplicates))

    # Ensure Phab task is properly formatted
    if (args.phab_task_id is not None and
            PHAB_TASK_PATTERN.search(args.phab_task_id) is None):
        raise ValueError(("Invalid Phabricator task ID '{task}', expected in "
                          "the form T12345").format(task=args.phab_task_id))

    return args


def ensure_shell_mode():
    """Ensure running in non-interactive mode or screen/tmux session or raise"""
    if os.isatty(0) and not (os.getenv('STY') or os.getenv('TMUX')):
        raise RuntimeError(
            'Must be run in non-interactive mode or inside a screen or tmux.')


def is_hostname_valid(hostname):
    """ Return True if the hostname is valid, False otherwise

        Arguments:
        hostname -- the hostname to validate
    """
    valid = False
    try:
        socket.gethostbyname(hostname)
        valid = True
    except socket.gaierror:
        valid = False

    return valid


def get_running_user():
    """Ensure running as root, the original user is detected and return it"""
    if os.getenv('USER') != 'root':
        raise RuntimeError('Unsufficient privileges, run with sudo')
    if os.getenv('SUDO_USER') in (None, 'root'):
        raise RuntimeError('Unable to determine real user')

    return os.getenv('SUDO_USER')


def setup_logging(user):
    """ Setup the logger instance and return the log file path

        Arguments:
        user -- the real user to use in the logging formatter for auditing
    """
    log_path = LOG_PATTERN.format(start=datetime.now().strftime('%Y%m%d%H%M'),
                                  user=user, pid=os.getpid())
    log_formatter = logging.Formatter(
        fmt=('%(asctime)s [%(levelname)s] ({user}) %(name)s::%(funcName)s: '
             '%(message)s').format(user=user),
        datefmt='%F %T')
    log_handler = FileHandler(log_path)
    log_handler.setFormatter(log_formatter)
    logger.addHandler(log_handler)
    logger.raiseExceptions = False
    logger.setLevel(logging.INFO)

    return log_path


def get_mgmt(host):
    """ Calculate and return the management console FQDN of a host or None

        Arguments:
        host -- the FQDN of the host
    """
    parts = host.split('.')
    if parts[-1] != INTERNAL_TLD:
        logger.debug(("Unable to calculate the management FQDN for "
                      "host '{host}'").format(host=host))
        return None

    parts.insert(1, MANAGEMENT_DOMAIN)
    mgmt = '.'.join(parts)

    if not is_hostname_valid(mgmt):
        logger.debug(("Unable to resolve calculated management FQDN for "
                      "host '{host}': '{mgmt}'").format(host=host, mgmt=mgmt))
        return None

    logger.debug("Management FQDN for '{host}' is '{mgmt}'".format(
        host=host, mgmt=mgmt))

    return mgmt


def get_custom_mgmts(hosts):
    """ Ask for the managment FQDN in case it's not automatically deductible

        Arguments:
        hosts -- the list of hosts to get the custom management console FQDN
    """
    mgmts = {}
    for host in hosts:
        if get_mgmt(host) is not None:
            continue

        while True:
            mgmt = raw_input("What is the MGMT FQDN for host '{host}'? ".format(
                host=host))

            if is_hostname_valid(mgmt):
                break
            else:
                print("Unable to resolve MGMT FQDN '{mgmt}'".format(mgmt=mgmt))

        mgmts[host] = mgmt
        logger.info("MGMT FQDN for host '{host}' is '{mgmt}'".format(
            host=host, mgmt=mgmts[host]))

    return mgmts


def get_phabricator_client():
    """Return a Phabricator client instance"""

    parser = ConfigParser.SafeConfigParser()
    parser_mode = 'phabricator_bot'
    parser.read(PHABRICATOR_CONFIG_FILE)

    host = parser.get(parser_mode, 'host')
    username = parser.get(parser_mode, 'username')
    client = Phabricator(
        host=host, username=username, token=parser.get(parser_mode, 'token'))
    logger.debug(("Initialized Phabricator client with host '{host}' and "
                  "username '{user}'").format(host=host, user=username))

    return client


def phabricator_task_update(phab_client, task_id, message):
    """ Add a comment on a Phabricator task

        Arguments:
        phab_client -- a Phabricator client instance
        task_id     -- the Phabricator task ID (T12345) to be updated
        message     -- the message to add
    """

    try:
        phab_client.maniphest.update(id=task_id[1:], comments=message)
        logger.info("Updated Phabricator task '{id}'".format(id=task_id))
    except Exception:
        logger.exception("Unable to update Phabricator task '{id}'".format(
            id=task_id))


def resolve_dns(name, record):
    """Resolve and return a DNS record for name"""
    target = str(dns.resolver.query(name, record)[0]).rsplit(
        ' ', 1)[-1].rstrip('.')
    if not is_hostname_valid(target):
        logger.error(("Resolved {record} '{target}' for name '{name}' is not a"
                      "recognized hostname").format(
            record=record, target=target, name=name))
        return

    logger.debug('Resolved {record} {target} for name {name}'.format(
        record=record, target=target, name=name))

    return target


def get_ipmi_password():
    """Get the IPMI password from the environment or ask for it and return it"""
    ipmi_password = os.getenv('IPMI_PASSWORD')

    if ipmi_password is None:
        logger.info('Missing IPMI_PASSWORD in the environment, asking for it')
        # Ask for a password, raise exception if not a tty
        ipmi_password = getpass.getpass(
            prompt='IPMI Password: ', stream=sys.stderr)
    else:
        logger.info('Found IPMI_PASSWORD in the environment, using it')

    if len(ipmi_password) == 0:
        raise RuntimeError('Empty IPMI_PASSWORD, please verify it')

    return ipmi_password


def log_salt_cmd_run(action, result, host=None):
    """ Log the result of a Salt cmd.run response

        Arguments:
        action -- the type of action that was executed
        result -- the 'data' dictionary of the Salt response
        host   -- an optional hostname the command was referring to
    """
    host_message = ''
    if host is not None:
        host_message = " (for host '{host}')".format(host=host)

    retvals = {}
    for key in ('id', 'retcode', 'success', 'return'):
        retvals[key] = result.get(key, '-')

    message = ("Run of '{action}' on host '{id}'{host_message} completed "
               "with exit code '{retcode}' and success '{success}':\n"
               "{return}").format(
        action=action, host_message=host_message, **retvals)

    if retvals['retcode'] == 0 or retvals['success'] is True:
        logger.info(message)
    else:
        logger.error(message)


def submit_job(target, action, params, audit_params=None, **kwargs):
    """ Submit an async Salt Job and return the job ID and the client instance

        Arguments:
        target       -- the Salt target hosts pattern
        action       -- the Salt module.function to call as string
        params       -- a list of parameters to pass to the module.function
        audit_params -- the parameters cleaned for logging purposes
        **kwargs     -- additional parameter for the Salt cmd_async function
    """
    # Checking multiple Job results in non-blocking mode is not supported
    # within the same client
    client = salt.client.LocalClient()

    # Returns int 0 if fails, str with Job ID on success
    jid = client.cmd_async(target, action, params, **kwargs)

    if jid == 0:
        logger.warning(("Unable to submit job to run '{action}' on target "
                        "'{target}'").format(action=action, target=target))
    else:
        if audit_params is None:
            audit_params = params

        logger.info(("Submitted job '{jid}' on target '{target}' with action "
                     "'{action}' and params '{params}'").format(
            jid=jid, target=target, action=action, params=audit_params))

    return (jid, client)


def run_command_on_hosts(targets, action, params=None, timeout=30,
                         silent=False, **kwargs):
    """ A generator to run a single Salt module.function on multiple hosts

        Arguments:
        targets  -- a list of target hosts
        action   -- the Salt module.function to call as string
        params   -- a list of parameters to pass to the module.function
        timeout  -- seconds after which stop waiting for answers. A value of 0
                    means to wait forever. [optional, default: 30]
        silent   -- suppress command logging [optional, default: False]
        **kwargs -- additional keyword arguments for the submit_job function
    """
    if len(targets) == 0:
        raise StopIteration()

    jobs = {}
    if params is None:
        params = []

    # Submit Jobs
    jid, client = submit_job(
        targets, action, params, expr_form='list', **kwargs)

    if jid == 0:
        raise StopIteration()

    jobs[jid] = {'targets': targets, 'client': client}

    # Wait for their results
    for _, result in watch_jobs(jobs, timeout=timeout):
        if not silent:
            log_salt_cmd_run(action, result)
        yield result


def proxy_command(action, target, hosts_commands, audit_commands=None,
                  timeout=30, silent=False, **kwargs):
    """ A generator to run hosts-based cmd.run commands from a single proxy host

        Arguments:
        action         -- a common name for the action for logging purposes
        target         -- the proxy host from where executing the commands
        hosts_commands -- a dictionary host: list of commands to be executed
        audit_commands -- a dictionary host: list of cleaned commands safe to
                          be logged [optional]
        timeout        -- seconds after which stop waiting for answers. A value
                          of 0 means to wait forever. [optional, default: 30]
        silent         -- suppress command logging [optional, default: False]
        **kwargs       -- additional optional keyword arguments for submit_job()
    """
    if len(hosts_commands) == 0:
        raise StopIteration()

    jobs = {}
    if audit_commands is None:
        audit_commands = hosts_commands

    # Submit Jobs
    for host, command in hosts_commands.iteritems():
        jid, client = submit_job(target, 'cmd.run', command,
                                 audit_params=audit_commands[host], **kwargs)
        time.sleep(1)  # Avoid conflicts (i.e. icinga_downtime)

        if jid == 0:
            continue

        jobs[jid] = {'targets': [target], 'host': host, 'client': client}

    # Wait for their results
    for host, result in watch_jobs(jobs, timeout=timeout):
        if not silent:
            log_salt_cmd_run(action, result, host)
        yield (host, result)


def watch_jobs(jobs, timeout=30):
    """ Generator that yields the job results as they are available

        Arguments:
        jobs    -- a dict with Salt Job IDs as keys and a dict with the list of
                   target hosts, the Salt client and an optional hostname as
                   values
        timeout -- seconds after which stop waiting for answers. A value of 0
                   means to wait forever. [optional, default: 30]
    """

    # Track Job completion
    start = datetime.now()
    running = set(jobs.keys())
    completed = set()

    # Track minion responses per Job
    expected = {jid: set(dest['targets']) for jid, dest in jobs.iteritems()}
    found = {jid: set() for jid in jobs.keys()}

    sleep = WATCHER_SHORT_SLEEP
    log_loops = 0
    while True:
        logger.debug('Watching for jobs: {jobs}'.format(
            jobs=(running - completed)))

        log_loops += 1
        if log_loops == WATCHER_SLEEP_THRESHOLD:
            log_loops = 1
            sleep = WATCHER_LONG_SLEEP

        for jid in running - completed:
            host = None
            if 'host' in jobs[jid]:
                host = jobs[jid]['host']

            try:
                # Get Job results or None
                for result in jobs[jid]['client'].get_returns_no_block(jid):
                    if result is None:
                        break  # No result yet, we'll retry at next loop
                    if 'return' not in result.get('data', {}):
                        continue  # Additional lines, skip

                    found_jid = result['data'].get('id', 0)
                    if 'retcode' not in result['data']:
                        result['data']['retcode'] = None
                    if 'success' not in result['data']:
                        result['data']['retcode'] = None

                    if found_jid != 0:
                        found[jid].add(found_jid)
                        yield (host, result['data'])

            except KeyError:
                # Fixes: https://github.com/saltstack/salt/issues/18994
                pass

            if found[jid] == expected[jid]:
                logger.info(("Job '{jid}' got response from all expected hosts"
                             ": {hosts}").format(jid=jid, hosts=found[jid]))
                completed.add(jid)
            elif found[jid] > expected[jid]:
                logger.error(("Job '{jid}' got response from unexpected hosts: "
                              "{hosts}").format(
                    jid=jid, hosts=(found[jid] - expected[jid])))

        if len(running - completed) == 0:
            break

        if log_loops == WATCHER_LOG_LOOPS and sleep == WATCHER_LONG_SLEEP:
            log_loops = 0
            logger.info('Job done ({done}/{total}), waiting for {jobs}'.format(
                done=len(completed), total=len(running),
                jobs=(running - completed)))

        if timeout > 0 and (datetime.now() - start).total_seconds() > timeout:
            logger.warning('Timeout reached for jobs: {jobs}'.format(
                jobs=(running - completed)))
            raise StopIteration()

        time.sleep(sleep)


def validate_hosts(puppetmaster_host, hosts, no_raise=False):
    """ Check that all hostnames have a signed certificate on the Puppet master

        Arguments:
        puppetmaster_host -- the hostname of the Puppet Master server
        hosts             -- the list of host to depool
        no_raise          -- do not raise on failure, just log
                             [optional, default: False]

        Raise:
        RuntimeError if any host is not valid and no_raise is False
    """
    command = "puppet cert list '{host}' 2> /dev/null"
    hosts_commands = {host: [command.format(host=host)] for host in hosts}

    for host, result in proxy_command(
            'validate_hosts', puppetmaster_host, hosts_commands):

        expected = '+ "{host}"'.format(host=host)
        if result['retcode'] != 0 or not result['return'].startswith(expected):
            message = ("Invalid host '{host}', signed cert on Puppet not "
                       "found and no_raise is {no_raise}: {output}").format(
                host=host, output=result['return'], no_raise=no_raise)

            if no_raise:
                logger.warning(message)
            else:
                raise RuntimeError(message)


def icinga_downtime(icinga_host, hosts, user, phab_task):
    """ Set downtime on Icinga for hosts and return the list of successful ones

        Arguments:
        icinga_host -- the hostname of the Icinga server
        hosts       -- the list of hosts to set downtime for
        user        -- the user that is executing the command
        phab_task   -- the related Phabricator task ID (i.e. T12345)

        Returns:
        The list of successfully depooled hosts
    """
    command = ("icinga-downtime -h '{host}' -d 14400 -r "
               "'wmf-auto-reimage: user={user} phab_task={phab_task}'")
    hosts_commands = {
        host: [command.format(host=host.split('.')[0], user=user,
                              phab_task=phab_task)] for host in hosts}
    success_hosts = []

    for host, result in proxy_command(
            'icinga_downtime', icinga_host, hosts_commands, timeout=300):

        if result['retcode'] == 0:
            success_hosts.append(host)

    print("Successfully set Icinga downtime for hosts: {hosts}".format(
        hosts=success_hosts))
    return success_hosts


def conftool_depool_hosts(puppetmaster_host, hosts):
    """ Depool hosts via conftool and return their previous status

        Arguments:
        puppetmaster_host -- the hostname of the Puppet Master server
        hosts             -- the list of host to depool

        Returns:
        A dictionary status: list of hosts for each conftool pooled status
    """
    command = "confctl --quiet select 'name={host}' set/pooled=inactive"
    hosts_commands = {host: [command.format(host=host)] for host in hosts}
    # Keep track of previous hosts status in conftool
    hosts_status = {'yes': [], 'no': [], 'inactive': []}

    for host, result in proxy_command(
            'conftool_depool_hosts', puppetmaster_host, hosts_commands):

        if result['retcode'] == 0:
            pattern = CONFTOOL_SET_INACTIVE_PATTERN.format(host=re.escape(host))
            match = re.search(pattern, result['return'])
            if match is None:
                logger.error("Unrecognized conftool output: {out}".format(
                    out=result['return']))
            else:
                hosts_status[match.groups()[0]].append(host)
        else:
            logger.error(("Unable to conftool 'set/pooled=inactive' host "
                          "'{host}'").format(host=host))

    print("Depooled via conftool, previous state was: {status}".format(
        status=hosts_status))
    return hosts_status


def conftool_ensure_depooled(puppetmaster_host, hosts):
    """ Check all given hosts are depooled and return the list of depooled ones

        Arguments:
        puppetmaster_host -- the hostname of the Puppet Master server
        hosts             -- the list of hosts to ensure are depooled
    """
    command = "confctl --quiet select 'name={host}' get"
    hosts_commands = {host: [command.format(host=host)] for host in hosts}
    success_hosts = []

    for host, result in proxy_command('conftool_ensure_depooled',
                                      puppetmaster_host, hosts_commands):

        if result['retcode'] == 0:
            status = json.loads(result['return'])
            if status[host]['pooled'] == 'inactive':
                success_hosts.append(host)

    print("Successfully ensured depooled for hosts: {hosts}".format(
        hosts=success_hosts))
    return success_hosts


def run_puppet(hosts):
    """ Run Puppet on hosts and return the list of successful ones

        TODO: handle the case in which Puppet was already running on the host
        TODO: change retcode handling when T145191 is fixed

        Arguments:
        hosts -- the list of hosts where to run Puppet
    """
    success_hosts = []

    for result in run_command_on_hosts(hosts, 'wmfpuppet.run', timeout=300):
        if result['success'] and result['return']['retcode'] == 0:
            success_hosts.append(result['id'])

    print("Successfully run Puppet on hosts: {hosts}".format(
        hosts=success_hosts))
    return success_hosts


def reimage_hosts(
        puppetmaster_host, hosts, custom_mgmts, ipmi_password, is_new=False):
    """ Reimage hosts, return the list of successful ones

        TODO: assuming all are successful for now because the minion job
              get lost, checking the uptime afterwards. Increase the timeout
              when fixed.

        Arguments:
        puppetmaster_host -- the hostname of the Puppet Master server
        hosts             -- the list of FQDN of the hosts to be reimaged
        ipmi_password     -- the password for the IPMI
        is_new            -- whether this is the first image for a new host
                             [optional, default: False]
    """
    # Hack to avoid a Salt parser bug. Using 'kwarg' doesn't work either
    # at least in our current version.
    command = ("true; IPMI_PASSWORD='{password}' wmf-reimage -s 10 {new} "
               "-y '{host}' '{mgmt}' | tee -a '/root/{host}.log'")

    success_hosts = []
    hosts_commands = {}
    audit_commands = {}

    if is_new:
        new = '--no-clean'
    else:
        new = ''

    print("Running wmf-reimage on hosts: {hosts}".format(hosts=hosts))

    for host in hosts:
        mgmt_host = get_mgmt(host)
        if mgmt_host is None:
            mgmt_host = custom_mgmts.get(host, False)

        if mgmt_host is None:
            logger.error("Unable to get MGMT FQDN for host '{host}'".format(
                host=host))
            continue

        hosts_commands[host] = [command.format(
            password=ipmi_password, new=new, host=host, mgmt=mgmt_host)]
        audit_commands[host] = [command.format(
            password='******', new=new, host=host, mgmt=mgmt_host)]
        print("wmf-reimage log is on {puppetmaster}:/root/{host}.log".format(
            puppetmaster=puppetmaster_host, host=host))

    for host, result in proxy_command(
            'reimage_hosts', puppetmaster_host, hosts_commands,
            audit_commands=audit_commands, timeout=900):

        if result['retcode'] == 0:
            success_hosts.append(host)

    # See TODO in the docstring
    print("Run wmf-reimage on hosts: {hosts}".format(hosts=hosts))
    return hosts


def check_reimage(puppetmaster_host, hosts):
    """ Check the reimage logs for completion

        Arguments:
        puppetmaster_host -- the hostname of the Puppet Master server
        hosts             -- the list of hostnames to check
    """
    timeout = 7200
    start = datetime.now()
    command = 'tail -n1 /root/{host}.log'
    hosts_commands = {host: [command.format(host=host)] for host in hosts}
    check_message = 'is now signed and both puppet and salt should work'
    success_hosts = []

    while True:
        for host, result in proxy_command('check_reimage', puppetmaster_host,
                                          hosts_commands, silent=True):

            if result['retcode'] == 0 and check_message in result['return']:
                success_hosts.append(host)
                del hosts_commands[host]

        if len(hosts_commands) == 0:
            break

        if (datetime.now() - start).total_seconds() > timeout:
            logger.error('Timeout reached')
            break

        time.sleep(WATCHER_LONG_SLEEP)

    if len(hosts_commands) != 0:
        logger.error("Waiting puppet not confirmed for '{hosts}'".format(
            hosts=hosts_commands.keys()))

    print("Successfully completed wmf-reimage for hosts: {hosts}".format(
        hosts=success_hosts))
    return success_hosts


def wait_puppet_run(hosts, start=None):
    """ Wait that a Puppet run is completed on the given hosts

        Arguments:
        hosts -- the list of hosts to monitor for a complete Puppet run
        start -- a datetime object to compare with Puppet last run
                 [optional, default: now()]

        Return:
        The list of hosts that completed Puppet
    """
    if start is None:
        start = datetime.now()

    hosts_set = set(hosts)
    success_hosts = set()
    timeout = 3600  # 1 hour
    retries = 0
    command = 'puppet.summary'

    while True:
        retries += 1
        logger.debug('Wating for Puppet ({retries})'.format(retries=retries))
        if retries % WATCHER_LOG_LOOPS == 0:
            logger.info('Still waiting for Puppet after {min} minutes'.format(
                min=(retries * WATCHER_LONG_SLEEP) / 60.0))

        hosts = list(hosts_set - success_hosts)
        for result in run_command_on_hosts(hosts, command, silent=True):
            if result is None or isinstance(result['return'], basestring):
                continue

            last_run = datetime.strptime(
                result['return']['last_run'], '%Y-%m-%dT%H:%M:%S')

            if result['retcode'] == 0 and last_run > start:
                success_hosts.add(result['id'])

        if success_hosts == hosts_set:
            break

        if (datetime.now() - start).total_seconds() > timeout:
            logger.error('Timeout reached')
            break

        time.sleep(WATCHER_LONG_SLEEP)

    if success_hosts != hosts_set:
        logger.error("Waiting puppet not confirmed for '{hosts}'".format(
            hosts=(hosts_set - success_hosts)))

    print("Puppet run check completed for hosts: {hosts}".format(
        hosts=list(success_hosts)))
    return list(success_hosts)


def reboot_hosts(hosts):
    """ Reboot hosts and return the list of successful ones

        TODO: assuming all are successful for now because sometimes the minion
              is not responding when rebooting and hit the timeout

        Arguments:
        hosts -- the list of hosts to be rebooted
    """
    success_hosts = []

    for result in run_command_on_hosts(hosts, 'system.reboot'):
        if result['retcode'] == 0:
            success_hosts.append(result['id'])

    # See TODO in the docstring
    print("Rebooted hosts: {hosts}".format(
        hosts=hosts))
    return hosts


def wait_reboot(hosts):
    """ Wait that the hosts are back online after a reboot

        Arguments:
        hosts -- the list of hosts to monitor

        Return:
        The list of hosts that respond to a test.ping
    """
    hosts_set = set(hosts)
    success_hosts = set()
    start = datetime.now()
    timeout = 600  # 10 minutes
    retries = 0

    while True:
        retries += 1
        logger.debug('Wating for reboot ({retries})'.format(retries=retries))
        if retries % WATCHER_LOG_LOOPS == 0:
            logger.info('Still waiting for reboot after {min} minutes'.format(
                min=(retries * WATCHER_LONG_SLEEP) / 60.0))

        hosts = list(hosts_set - success_hosts)
        for result in run_command_on_hosts(hosts, 'test.ping',
                                           timeout=5, silent=True):
            if result['retcode'] == 0 and result['return'] is True:
                success_hosts.add(result['id'])

        if success_hosts == hosts_set:
            break

        if (datetime.now() - start).total_seconds() > timeout:
            logger.error('Timeout reached')
            break

        time.sleep(WATCHER_LONG_SLEEP)

    if success_hosts != hosts_set:
        logger.error("Waiting reboot not confirmed for '{hosts}'".format(
            hosts=(hosts_set - success_hosts)))

    print("Successful reboot on hosts: {hosts}".format(
        hosts=list(success_hosts)))
    return list(success_hosts)


def check_uptime(hosts, minimum=0, maximum=None):
    """ Check that the uptime is between limits

        minimum <= uptime <= maximum

        Arguments:
        hosts   -- the list of hosts where to check the uptime
        minimum -- uptime has to be greater than these seconds
                   [optional, default: 0]
        maximum -- uptime has to be less than these seconds [optional]

        Return:
        The list of hosts that has an uptime within the limits
    """
    success_hosts = []

    for result in run_command_on_hosts(
            hosts, 'cmd.run', params=['cat /proc/uptime']):

        if result['retcode'] != 0:
            continue

        try:
            uptime = int(result['return'].strip().split('.')[0])
        except Exception:
            logger.error(("Unable to determine uptime of host '{host}': "
                          "{uptime}").format(
                host=result['id'], uptime=result['return']))
            continue

        if uptime < minimum or (maximum is not None and uptime > maximum):
            logger.error(("Uptime for host '{host}' not within expected "
                          "limits: {minimum} <= {uptime} <= {maximum}").format(
                host=result['id'], minimum=minimum, uptime=uptime,
                maximum=maximum))
            continue

        success_hosts.append(result['id'])

    print("Successful uptime check on hosts: {hosts}".format(
        hosts=success_hosts))
    return success_hosts


def run_apache_fast_test(deployment_host, hosts):
    """ Run apache-fast-test from tin on the given hosts

        TODO: move out of oblivian's home and better define tin host

        Arguments:
        deployment_host -- the deployment host from where to run the test
        hosts           -- the list of hosts to be checked

        Returns:
        The list of successful ones
    """
    command = 'apache-fast-test ~oblivian/baseurls {host}'
    hosts_commands = {host: [command.format(host=host.split('.')[0])]
                      for host in hosts}
    success_hosts = []

    for host, result in proxy_command('run_apache_fast_test', deployment_host,
                                      hosts_commands, timeout=120):

        if result['retcode'] == 0:
            success_hosts.append(host)

    print("Successfully run Apache fast-test on hosts: {hosts}".format(
        hosts=success_hosts))
    return success_hosts


def get_repool_message(hosts_status):
    """ Return a message with the commands to repool the depooled hosts

        Arguments:
        hosts_status -- a dictionary status: list of hosts for each status
    """
    command = "confctl --quiet select 'name={host}' set/pooled={status}"
    commands = []

    for status, hosts in hosts_status.iteritems():
        commands += [command.format(host=host, status=status) for host in hosts]

    message = ("To set back the conftool status to their previous values run:\n"
               "```\n{repool}\n```").format(repool='\n'.join(commands))

    print(message)
    return message


def get_phabricator_post_message(hosts, successful, hosts_status=None):
    """ Return the result message to append to the Phabricator task

        Arguments:
        hosts        -- the list of hosts that were reimaged
        successful   -- the list of successfully reimaged hosts
        hosts_status -- a dictionary status: list of hosts for each status
                        for conftool
    """
    hosts_set = set(hosts)
    successful_set = set(successful)
    failed = hosts_set - successful_set

    if failed:
        result = PHAB_COMMENT_POST_FAILED.format(failed=failed)
    else:
        result = PHAB_COMMENT_POST_SUCCESS

    notes = ''
    if hosts_status is not None:
        notes = get_repool_message(hosts_status)

    message = '{common}\n{result}\n{notes}'.format(
        common=PHAB_COMMENT_POST.format(hosts=hosts),
        result=result, notes=notes)

    return message


def run(args, user, log_path):
    """ Run the WMF auto reimage according to command line arguments

        Arguments:
        args     -- parsed command line arguments
        user     -- the user that launched the script, for auditing purposes
        log_path -- the path of the logfile
    """
    # Get additional informations
    ipmi_password = get_ipmi_password()
    custom_mgmts = get_custom_mgmts(args.hosts)
    icinga_host = resolve_dns(ICINGA_DOMAIN, 'CNAME')
    puppetmaster_host = resolve_dns(PUPPET_DOMAIN, 'CNAME')
    deployment_host = resolve_dns(DEPLOYMENT_DOMAIN, 'CNAME')
    phab_client = get_phabricator_client()
    hosts = args.hosts
    hosts_status = None

    # Validate hosts
    if not args.new:
        validate_hosts(puppetmaster_host, args.hosts, args.no_verify)

    # Update the Phabricator task
    if args.phab_task_id is not None:
        phabricator_task_update(
            phab_client, args.phab_task_id, PHAB_COMMENT_PRE.format(
                user=user, hostname=socket.getfqdn(), hosts=hosts,
                log=log_path))

    # Set downtime on Icinga
    if not args.new:
        hosts = icinga_downtime(icinga_host, hosts, user, args.phab_task_id)

    # Depool via conftool
    if args.conftool and not args.new:
        hosts_status = conftool_depool_hosts(puppetmaster_host, hosts)
        hosts = conftool_ensure_depooled(puppetmaster_host, hosts)
        # Run Puppet on the deployment host to update DSH groups
        if len(hosts) > 0:
            run_puppet([deployment_host])

    # Start the reimage
    reimage_time = datetime.now()
    hosts = reimage_hosts(puppetmaster_host, hosts, custom_mgmts=custom_mgmts,
                          ipmi_password=ipmi_password, is_new=args.new)
    hosts = check_reimage(puppetmaster_host, hosts)
    hosts = check_uptime(
        hosts, maximum=int((datetime.now() - reimage_time).total_seconds()))

    # Wait for Puppet
    hosts = wait_puppet_run(hosts, start=reimage_time)

    if not args.no_reboot:
        # Issue a reboot and wait for it and also for Puppet to complete
        reboot_time = datetime.now()
        hosts = reboot_hosts(hosts)
        boot_time = datetime.now()
        hosts = wait_reboot(hosts)
        hosts = check_uptime(
            hosts, maximum=int((datetime.now() - reboot_time).total_seconds()))
        hosts = wait_puppet_run(hosts, start=boot_time)

    # Check Icinga alarms, put again in downtime if was cleared or --new is set
    # TODO

    # Run Apache fast test
    if args.apache:
        hosts = run_apache_fast_test(deployment_host, hosts)

    # The repool is *not* done automatically the command to repool is added
    # to the Phabricator task

    # Comment on the Phabricator task
    if args.phab_task_id is not None:
        phabricator_message = get_phabricator_post_message(
            args.hosts, hosts, hosts_status=hosts_status)
        phabricator_task_update(
            phab_client, args.phab_task_id, phabricator_message)

    logger.info(("Auto reimaging of hosts '{hosts}' completed, hosts "
                 "'{successful}' were successful.").format(
        hosts=args.hosts, successful=hosts))


def main():
    """Run the automated reimaging of a list of hosts"""
    # Setup
    args = parse_args()
    ensure_shell_mode()
    user = get_running_user()
    log_path = setup_logging(user)
    if args.debug:
        logger.setLevel(logging.DEBUG)

    logger.info('wmf_auto_reimage called with args: {args}'.format(args=args))

    try:
        print('START')
        print('To monitor the full log:\ntail -F {log}'.format(log=log_path))
        run(args, user, log_path)
    except Exception as e:
        message = 'Unable to run wmf_auto_reimage'
        print('{message}: {error}'.format(message=message, error=e))
        logger.exception(message)
    finally:
        print('END')


if __name__ == '__main__':
    main()
