#!/usr/bin/env python
"""Automated reimaging of a machine"""

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
from logging.handlers import RotatingFileHandler

import dns.resolver
import salt.client

from phabricator import Phabricator

ICINGA_DOMAIN = 'icinga.wikimedia.org'
PUPPET_DOMAIN = 'puppet.wikimedia.org'
INTERNAL_TLD = 'wmnet'
MANAGEMENT_DOMAIN = 'mgmt'

LOG_PATH = '/var/log/wmf_auto_reimage.log'
# TODO: move it to a deicated ops-orchestration-bot
PHABRICATOR_CONFIG_FILE = '/etc/phabricator_ops-monitoring-bot.conf'

PHAB_COMMENT_PRE = ('Script wmf_auto_reimage was launched by {user} on '
                    '{hostname} for hosts:\n```\n{hosts}\n```\n'
                    'The log can be found in `{log}`.')
PHAB_COMMENT_POST = ('Completed auto-reimage of hosts:\n```\n{hosts}\n```\n'
                     'Those hosts were successful:\n```\n{successful}\n```\n'
                     '{notes}')


WATCHER_SLEEP_THRESHOLD = 10  # Use the WATCHER_LONG_SLEEP after those loops
WATCHER_SHORT_SLEEP = 3  # Seconds to sleep between loops before the threshold
WATCHER_LONG_SLEEP = 60  # Seconds to sleep between loops after the threshold
WATCHER_LOG_LOOPS = 5  # Log progress after this number of long sleep loops

HOSTS_PATTERN = re.compile('^[a-z0-9.-]+$')

logger = logging.getLogger('wmf_auto_reimage')


def parse_args():
    """ Parse and return command line arguments, validate the hosts"""

    parser = argparse.ArgumentParser(
        description='Automated reimaging of a machine')
    parser.add_argument(
        '-c', dest='conftool', action='store_true',
        help='Depool the machine via conftool before proceeding')
    parser.add_argument(
        '-a', dest='apache', action='store_true',
        help='Run apache-fast-test on the hosts after the reimage')
    parser.add_argument(
        '-p', dest='phab_task_id', action='store', required=True,
        help='The Phabricator task ID (T12345)')
    parser.add_argument(
        '-d', dest='debug', action='store_true', help='Debug level logging')
    parser.add_argument(
        'hosts', metavar='HOST', nargs='+', action='store',
        help='FQDN of the machine(s) to be reimaged')

    args = parser.parse_args()

    # Perform a quick sanity check on the hosts parameter
    for host in args.hosts:
        if '.' not in host or not HOSTS_PATTERN.match(host):
            raise ValueError("Expected FQDN of hosts, got '{host}'".format(
                host=host))

    return args


def ensure_shell_mode():
    """Ensure running in non-interactive mode or screen/tmux session or raise"""
    if os.isatty(0) and not (os.getenv('STY') or os.getenv('TMUX')):
        raise RuntimeError(
            'Must be run in non-interactive mode or inside a screen or tmux.')


def get_running_user():
    """Ensure running as root, the original user is detected and return it"""
    if os.getenv('USER') != 'root':
        raise RuntimeError('Unsufficient privileges, run with sudo')
    if os.getenv('SUDO_USER') in (None, 'root'):
        raise RuntimeError('Unable to determine real user')

    return os.getenv('SUDO_USER')


def setup_logging(user):
    """ Setup the logger instance

        Arguments:
        user -- the real user to use in the logging formatter for auditing
    """
    log_formatter = logging.Formatter(
        fmt=('%(asctime)s [%(levelname)s] ({user}) %(name)s::%(funcName)s: '
             '%(message)s').format(user=user),
        datefmt='%F %T')
    log_handler = RotatingFileHandler(
        LOG_PATH, maxBytes=5*(1024**2), backupCount=10)
    log_handler.setFormatter(log_formatter)
    logger.addHandler(log_handler)
    logger.raiseExceptions = False
    logger.setLevel(logging.INFO)


def get_mgmt(host):
    """ Return the FQDN of the management console of a host or None

        Arguments:
        host -- the FQDN of the host
    """
    parts = host.split('.')
    if parts[-1] != INTERNAL_TLD:
        logger.debug(("Unable to determine management FQDN for "
                      "host '{host}'").format(host=host))
        return None

    parts.insert(1, MANAGEMENT_DOMAIN)
    mgmt = '.'.join(parts)
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
        if get_mgmt(host) is None:
            mgmts[host] = raw_input(
                "What is the MGMT FQDN for host '{host}'? ".format(host=host))
            logger.info("MGMT FQD for host '{host}' is '{mgmt}'".format(
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


def resolve_cname(name):
    """Resolve and return a DNS CNAME"""
    cname = str(dns.resolver.query(name, 'CNAME')[0]).rstrip('.')
    logger.debug('Resolved CNAME {cname} for name {name}'.format(
        cname=cname, name=name))

    return cname


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

    message = ("Run of '{action}' on host '{target}'{host_message} completed "
               "with exit code '{retcode}':\n{output}").format(
        action=action, target=result['id'], host_message=host_message,
        retcode=result['retcode'], output=result['return'])

    if result['retcode'] == 0:
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
        logger.error(("Unable to submit job to run '{action}' on "
                      "target '{target}'").format(action=action, target=target))
    else:
        if audit_params is None:
            audit_params = params

        logger.info(("Submitted job '{jid}' on target '{target}' with action "
                     "'{action}' and params '{params}'").format(
            jid=jid, target=target, action=action, params=audit_params))

    return (jid, client)


def run_command_on_hosts(targets, action, params=None, **kwargs):
    """ A generator to run a single Salt module.function on multiple hosts

        Arguments:
        targets  -- a list of target hosts
        action   -- the Salt module.function to call as string
        params   -- a list of parameters to pass to the module.function
        **kwargs -- additional keyword arguments for the submit_job function
    """
    jobs = {}
    if params is None:
        params = []

    # Submit Jobs
    jid, client = submit_job(
        targets, action, params, expr_form='list', **kwargs)

    jobs[jid] = {'targets': targets, 'client': client}

    # Wait for their results
    for _, result in watch_jobs(jobs):
        log_salt_cmd_run(action, result)
        yield result


def proxy_command(action, target, hosts_commands,
                  audit_commands=None, **kwargs):
    """ A generator to run hosts-based cmd.run commands from a single proxy host

        Arguments:
        action         -- a common name for the action for logging purposes
        target         -- the proxy host from where executing the commands
        hosts_commands -- a dictionary host: list of commands to be executed
        audit_commands -- a dictionary host: list of cleaned commands safe to
                          be logged [optional]
        **kwargs       -- additional optional keyword arguments for submit_job()
    """
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
    for host, result in watch_jobs(jobs):
        log_salt_cmd_run(action, result, host)
        yield (host, result)


def watch_jobs(jobs):
    """ Generator that yields the job results as they are available

        Arguments:
        jobs -- a dict with Salt Job IDs as keys and a dict with the list of
                target hosts, the Salt client and an optional hostname as values
    """

    # Track Job completion
    running = set(jobs.keys())
    completed = set()

    # Track minion responses per Job
    expected = {jid: set(dest['targets']) for jid, dest in jobs.iteritems()}
    found = {jid: set() for jid in jobs.keys()}

    sleep = WATCHER_SHORT_SLEEP
    log_loops = 0
    while True:
        logger.debug('Watching for jobs...')

        log_loops += 1
        if log_loops == WATCHER_SLEEP_THRESHOLD:
            log_loops = 1
            sleep = WATCHER_LONG_SLEEP

        for jid in running - completed:
            try:
                host = None
                if 'host' in jobs[jid]:
                    host = jobs[jid]['host']

                # Get Job results or None
                for result in jobs[jid]['client'].get_returns_no_block(jid):
                    if result is None:
                        break  # No result yet, we'll retry at next loop
                    if 'return' not in result.get('data', {}):
                        continue  # Additional lines, skip

                    found[jid].add(result['data']['id'])
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
            logger.info('Job completion progress: {done}/{total}'.format(
                done=len(completed), total=len(running)))

        time.sleep(sleep)


def validate_hosts(puppetmaster_host, hosts):
    """ Check that all hostnames have a signed certificate on the Puppet master

        Arguments:
        puppetmaster_host -- the hostname of the Puppet Master server
        hosts             -- the list of host to depool

        Raise:
        RuntimeError if any host is not valid
    """
    command = "puppet cert list '{host}'"
    hosts_commands = {host: [command.format(host=host)] for host in hosts}

    for host, result in proxy_command(
            'validate_hosts', puppetmaster_host, hosts_commands):

        expected = '+ "{host}"'.format(host=host)
        if result['retcode'] != 0 or not result['return'].startswith(expected):
            raise RuntimeError(("Invalid host '{host}', signed cert on Puppet "
                                "not found: {output}").format(
                host=host, output=result['return']))


def icinga_downtime(icinga_host, hosts, phab_task):
    """ Set downtime on Icinga for hosts and return the list of successful ones

        Arguments:
        icinga_host -- the hostname of the Icinga server
        hosts       -- the list of hosts to set downtime for
        phab_task   -- the related Phabricator task ID (i.e. T12345)

        Returns:
        The list of successfully depooled hosts
    """
    command = ("icinga-downtime -h '{host}' -d 7200 -r "
               "'Reimaging: {phab_task}'")
    hosts_commands = {
        host: [command.format(host=host.split('.')[0], phab_task=phab_task)]
        for host in hosts}
    success_hosts = []

    for host, result in proxy_command(
            'icinga_downtime', icinga_host, hosts_commands):

        if result['retcode'] == 0:
            success_hosts.append(host)

    return success_hosts


def conftool_depool_hosts(puppetmaster_host, hosts):
    """ Depool hosts via conftool and return the list of successful ones

        Arguments:
        puppetmaster_host -- the hostname of the Puppet Master server
        hosts             -- the list of host to depool
    """
    command = "confctl --quiet select 'name={host}' set/pooled=no"
    hosts_commands = {host: [command.format(host=host)] for host in hosts}
    success_hosts = []

    for host, result in proxy_command(
            'conftool_depool_hosts', puppetmaster_host, hosts_commands):

        expected = '{host}: pooled changed yes => no'.format(host=host)
        if result['retcode'] == 0 and result['return'] == expected:
            success_hosts.append(host)

    return success_hosts


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

        status = json.loads(result['return'])
        if result['retcode'] == 0 and status[host]['pooled'] == 'no':
            success_hosts.append(host)

    return success_hosts


def reimage_hosts(puppetmaster_host, hosts, custom_mgmts, ipmi_password):
    """ Reimage hosts, return the list of successful ones

        Arguments:
        puppetmaster_host -- the hostname of the Puppet Master server
        hosts             -- the list of FQDN of the machines to be reimaged
        ipmi_password     -- the password for the IPMI
    """
    command = ("IPMI_PASSWORD='{password}' wmf-reimage -s 10 "
               "-y '{host}' '{mgmt}'")

    success_hosts = []
    hosts_commands = {}
    audit_commands = {}

    for host in hosts:
        mgmt_host = get_mgmt(host)
        if mgmt_host is None:
            mgmt_host = custom_mgmts.get(host, False)

        if mgmt_host is None:
            logger.error("Unable to get MGMT FQDN for host '{host}'".format(
                host=host))
            continue

        hosts_commands[host] = [command.format(
            password=ipmi_password, host=host, mgmt=mgmt_host)]
        audit_commands[host] = [command.format(
            password='******', host=host, mgmt=mgmt_host)]

    for host, result in proxy_command(
            'reimage_hosts', puppetmaster_host, hosts_commands,
            audit_commands=audit_commands, timeout=60*30):

        if result['retcode'] == 0:
            success_hosts.append(host)

    return success_hosts


def wait_puppet_run(hosts):
    """ Wait that a Puppet run is completed on the given hosts

        Arguments:
        hosts -- the list of hosts to monitor for a complete Puppet run

        Return:
        The list of hosts that completed Puppet
    """
    logger.info(
        'Executing periodic puppet.summary on {hosts}'.format(hosts=hosts))

    start = datetime.now()
    hosts_set = set(hosts)
    success_hosts = set()
    retries = 0

    while True:
        retries += 1
        logger.debug('Wating for Puppet ({retries})'.format(retries=retries))
        if retries % WATCHER_LOG_LOOPS == 0:
            logger.info('Still waiting for Puppet after {min} minutes'.format(
                min=(retries * WATCHER_LONG_SLEEP) / 60.0))

        for result in run_command_on_hosts(hosts, 'puppet.summary'):
            last_run = datetime.strptime(
                result['return']['last_run'], '%Y-%m-%dT%H:%M:%S')

            if result['retcode'] == 0 and last_run > start:
                success_hosts.add(result['id'])

        if success_hosts == hosts_set:
            break

        time.sleep(WATCHER_LONG_SLEEP)

    return list(success_hosts)


def reboot_hosts(hosts):
    """ Reboot hosts and return the list of successful ones

        Arguments:
        hosts -- the list of hosts to be rebooted
    """
    success_hosts = []
    logger.info('Executing system.reboot on {hosts}'.format(hosts=hosts))

    for result in run_command_on_hosts(hosts, 'system.reboot'):
        if result['retcode'] == 0:
            success_hosts.append(result['id'])

    return success_hosts


def run_apache_fast_test(hosts):
    """ Run apache-fast-test from tin on the given hosts

        TODO: move out of oblivian's home and better define tin host

        Arguments:
        hosts -- the list of hosts to be checked

        Returns:
        The list of successful ones
    """
    tin_host = 'tin.eqiad.wmnet'
    command = 'apache-fast-test ~oblivian/baseurls {host}'
    hosts_commands = {host: [command.format(host=host.split('.')[0])]
                      for host in hosts}
    success_hosts = []

    for host, result in proxy_command(
            'run_apache_fast_test', tin_host, hosts_commands):

        if result['retcode'] == 0:
            success_hosts.append(host)

    return success_hosts


def get_repool_message(hosts):
    """ Return a message with the commands to repool the depooled hosts

        Arguments:
        hosts -- the list of hosts to include in the repool message
    """
    command = "confctl --quiet select 'name={host}' set/pooled=yes"
    commands = [command.format(host=host) for host in hosts]

    message = ('Those hosts were pooled, to repool them run:\n'
               '```\n{repool}\n```').format(repool='\n'.join(commands))

    return message


def run(args, user):
    """ Run the WMF auto reimage according to command line arguments

        Arguments:
        args -- parsed command line arguments
        user -- the user that launched the script, for auditing purposes
    """
    # Get additional informations
    ipmi_password = get_ipmi_password()
    custom_mgmts = get_custom_mgmts(args.hosts)
    icinga_host = resolve_cname(ICINGA_DOMAIN)
    puppetmaster_host = resolve_cname(PUPPET_DOMAIN)
    phab_client = get_phabricator_client()
    hosts = args.hosts
    depooled_hosts = []

    # Validate hosts
    validate_hosts(puppetmaster_host, args.hosts)

    # Update the Phabricator task
    phabricator_task_update(
        phab_client, args.phab_task, PHAB_COMMENT_PRE.format(
            user=user, hostname=socket.getfqdn(), hosts=hosts, log=LOG_PATH))

    # Set downtime on Icinga
    hosts = icinga_downtime(icinga_host, hosts, args.phab_task)

    # Depool via conftool
    if args.conftool:
        depooled_hosts = conftool_depool_hosts(puppetmaster_host, hosts)
        hosts = conftool_ensure_depooled(puppetmaster_host, hosts)

    # Start the reimage
    hosts = reimage_hosts(puppetmaster_host, hosts, custom_mgmts=custom_mgmts,
                          ipmi_password=ipmi_password)

    # Wait for Puppet
    hosts = wait_puppet_run(hosts)

    # Issue a reboot
    hosts = reboot_hosts(hosts)

    # Wait for the reboot
    # TODO: do it with a test.ping
    time.sleep(300)

    # Wait for Puppet
    hosts = wait_puppet_run(hosts)

    # Check Icinga alarms
    # TODO

    # Run Apache fast test
    if args.apache:
        hosts = run_apache_fast_test(hosts)

    # Repool (manually for now)
    notes = ''
    if args.conftool:
        notes = get_repool_message(depooled_hosts)

    # Comment on the Phabricator task
    phabricator_task_update(
        phab_client, args.phab_task,
        PHAB_COMMENT_POST.format(
            hosts=args.hosts, successful=hosts, notes=notes))

    logger.info(("Auto reimaging of hosts '{hosts}' completed, "
                 "Phab task '{task_id}' updated.").format(
        args.hosts, args.phab_task))


def main():
    """Run the automated reimaging of a machine"""
    # Setup
    ensure_shell_mode()
    user = get_running_user()
    setup_logging(user)
    args = parse_args()
    if args.debug:
        logger.setLevel(logging.DEBUG)

    logger.info('wmf_auto_reimage called with args: {args}'.format(args=args))

    try:
        run(args, user)
    except Exception:
        logger.exception('Unable to run wmf_auto_reimage')


if __name__ == '__main__':
    main()
