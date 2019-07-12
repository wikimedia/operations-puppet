#!/usr/bin/env python3
"""Library for the wmf-auto-reimage and wmf-auto-reimage-host scripts."""
import argparse
import configparser
import getpass
import logging
import os
import re
import socket
import subprocess
import sys
import time

from collections import defaultdict
from datetime import datetime
from logging import FileHandler

import cumin
import dns.resolver
import requests

from conftool import configuration, kvobject, loader
from conftool.drivers import BackendError
from cumin import query, transport, transports
from phabricator import Phabricator


ICINGA_DOMAIN = 'icinga.wikimedia.org'
DEPLOYMENT_DOMAIN = 'deployment.eqiad.wmnet'
DEBMONITOR_URL = 'https://debmonitor.discovery.wmnet/hosts/{host}'
DEBMONITOR_CERT = '/etc/debmonitor/ssl/cert.pem'
DEBMONITOR_KEY = '/etc/debmonitor/ssl/server.key'
INTERNAL_TLD = 'wmnet'
MANAGEMENT_DOMAIN = 'mgmt'
CERT_DESTROY = 'destroy'

LOG_PATTERN = '/var/log/wmf-auto-reimage/{start}_{user}_{pid}.log'
# TODO: move it to a dedicated ops-orchestration-bot
PHABRICATOR_CONFIG_FILE = '/etc/phabricator_ops-monitoring-bot.conf'

PHAB_COMMENT_PRE = ('Script wmf-auto-reimage was launched by {user} on '
                    '{hostname} for hosts:\n```\n{hosts}\n```\n'
                    'The log can be found in `{log}`.')
PHAB_COMMENT_POST = 'Completed auto-reimage of hosts:\n```\n{hosts}\n```\n'
PHAB_COMMENT_POST_SUCCESS = 'and were **ALL** successful.\n'
PHAB_COMMENT_POST_FAILED = 'Of which those **FAILED**:\n```\n{failed}\n```\n'

WATCHER_LONG_SLEEP = 60  # Seconds to sleep between loops after the threshold
WATCHER_LOG_LOOPS = 5  # Log progress after this number of long sleep loops

PHAB_TASK_PATTERN = re.compile('^T[0-9]+$')
HOSTS_PATTERN = re.compile('^[a-z0-9.-]+$')

logger = logging.getLogger('wmf-auto-reimage')
cumin_config = cumin.Config()
cumin_config_installer = cumin.Config('/etc/cumin/config-installer.yaml')
safe_stdout = sys.stdout


# Temporarily borrowed code from switchdc until we move the reimage functionality into
# the spin-off from switchdc.
class Confctl(object):
    """Get and set conftool object values."""

    def __init__(self, obj_type, config='/etc/conftool/config.yaml',
                 schema='/etc/conftool/schema.yaml'):
        self._schema = loader.Schema.from_file(schema)
        self.entity = self._schema.entities[obj_type]
        kvobject.KVObject.setup(configuration.get(config))

    def _select(self, tags):
        selectors = {}
        for tag, expr in tags.items():
            selectors[tag] = re.compile('^{}$'.format(expr))
        for obj in self.entity.query(selectors):
            yield obj

    def update(self, changed, **tags):
        """Update the conftool objects value that match the selection done with tags.

        Example:
          confctl.update({'pooled': False}, service='appservers-.*', name='eqiad')
        """
        logger.debug('Updating conftool matching tags: {tags}'.format(tags=tags))

        for obj in self._select(tags):
            logger.debug('Updating conftool: {obj} -> {changed}'.format(obj=obj, changed=changed))

            try:
                obj.update(changed)
            except BackendError as e:
                logger.error('Error writing to etcd: %s', e)
                raise RuntimeError(e)
            except Exception as e:
                logger.error('Generic error in conftool: %s', e)
                raise RuntimeError(e)

    def get(self, **tags):
        """Get conftool objects corresponding to the selection."""
        for obj in self._select(tags):
            logger.debug('Selected conftool object: {obj}'.format(obj=obj))
            yield obj


def get_base_parser(description):
    """Return an ArgumentParser with the common base options.

    If new options are added, they must be handled also in get_reimage_host_command().

    Arguments:
    description -- the description to use for the ArgumentParser
    """
    parser = argparse.ArgumentParser(description=description)
    parser.add_argument(
        '-d', '--debug', action='store_true', help='debug level logging')
    parser.add_argument(
        '--no-reboot', action='store_true',
        help='do not reboot the hosts after the reimage and the first Puppet run')
    parser.add_argument(
        '--no-verify', action='store_true',
        help=('do not fail if hosts verification fails, just log it. Has no '
              'effect if --new is also set.'))
    parser.add_argument(
        '--no-downtime', action='store_true',
        help='do not set the host in downtime on Icinga. Included if --new is set.')
    parser.add_argument(
        '--no-pxe', action='store_true',
        help=('do not reboot into PXE and reimage. To be used when the reimage had issues and was '
              'manually fixed.'))
    parser.add_argument(
        '--new', action='store_true',
        help=('for first imaging of new hosts that are not in puppet yet and this is their first'
              'imaging. Skips some steps on old hosts, includes --no-verify'))
    parser.add_argument(
        '-c', '--conftool', action='store_true',
        help=("Depool the host(s) via conftool with the value of the --conftool-value option. "
              "If the --conftool-value option is not set, its default value of 'inactive' will be "
              "used. The host(s) will NOT be repooled automatically, but the repool commands will "
              "be printed at the end. If --new is also set, it will just print the pool message "
              "at the end."))
    parser.add_argument(
        '--conftool-value', default='inactive',
        help=("Value to pass to the 'set/pooled' command in conftool to depool the host(s), if "
              "the -c/--conftool option is set. [default: inactive]"))
    parser.add_argument(
        '--mask',
        help=('Comma separated list of names of systemd services to mask before the first Puppet '
              'run, without the .service suffix. Useful when the first Puppet run already '
              'start/enable some production services before the host is ready.'))
    parser.add_argument(
        '-a', '--apache', action='store_true',
        help='run apache-fast-test on the hosts after the reimage')
    parser.add_argument(
        '-p', '--phab-task-id', action='store',
        help='the Phabricator task ID, i.e.: T12345)')

    return parser


def ensure_shell_mode():
    """Ensure it is running in non-interactive mode or screen/tmux session, raise otherwise."""
    if (os.isatty(0) and not os.getenv('STY', '') and not os.getenv('TMUX', '')
            and 'screen' not in os.getenv('TERM', '')):
        raise RuntimeError(
            'Must be run in non-interactive mode or inside a screen or tmux.')


def is_hostname_valid(hostname):
    """Return True if the hostname is valid, False otherwise.

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
    """Ensure running as root, the original user is detected and return it."""
    if os.getenv('USER') != 'root':
        raise RuntimeError('Unsufficient privileges, run with sudo')
    if os.getenv('SUDO_USER') in (None, 'root'):
        raise RuntimeError('Unable to determine real user')

    return os.getenv('SUDO_USER')


def setup_logging(logger, user, log_path):
    """Set up the logger instance

    Arguments:
    logger   -- a logging.Logger instance
    user     -- the real user to use in the logging formatter for auditing
    log_path -- the path where to save the log file
    """
    log_formatter = logging.Formatter(
        fmt=('%(asctime)s [%(levelname)s] ({user}) %(name)s::%(funcName)s: '
             '%(message)s').format(user=user),
        datefmt='%F %T')
    log_handler = FileHandler(log_path)
    log_handler.setFormatter(log_formatter)
    logger.addHandler(log_handler)
    logger.raiseExceptions = False
    logger.setLevel(logging.INFO)


def print_line(message, host=None, skip_time=False, level=logging.INFO):
    """Print and flush a message do stdout.

    Arguments:
    message   -- the message to print
    host      -- the host to which the message belongs to. [optional]
    skip_time -- whether to not print the datetime at the start of the line [optional]
    level     -- level to use to log the message, one of logging's module levels [optional]
    """
    parts = []

    if not skip_time:
        parts = [datetime.utcnow().strftime('%H:%M:%S')]

    if host is not None:
        parts.append(host)

    parts.append(message)

    print(' | '.join(parts), file=safe_stdout)  # noqa: E999 TODO: remove once tox:pep8 uses python3
    safe_stdout.flush()
    logger.log(level, message)


def get_mgmt(host):
    """Calculate and return the management console FQDN of a host or None.

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


def get_mgmts(hosts):
    """Ask for the managment FQDNs of the given hosts in case it's not automatically deductible.

    Arguments:
    hosts -- the list of hosts to get the management console FQDN

    Returns:
    dictionary with the hostnames as keys and the managment FQDNs as values
    """
    mgmts = {}
    for host in hosts:
        mgmt = get_mgmt(host)
        if mgmt is not None:
            mgmts[host] = mgmt
            continue

        while True:
            mgmt = input("What is the MGMT FQDN for host '{host}'? ".format(host=host))

            if is_hostname_valid(mgmt):
                break
            else:
                print_line("Unable to resolve MGMT FQDN '{mgmt}'".format(mgmt=mgmt))

        mgmts[host] = mgmt
        logger.info("MGMT FQDN for host '{host}' is '{mgmt}'".format(
            host=host, mgmt=mgmts[host]))

    return mgmts


def check_remote_ipmi(mgmt):
    """Ensure that remote IPMI is working, raise exception otherwise.

    Arguments:
    mgmt -- the FQDN of the management console to check the remote IPMI for
    """
    try:
        status = ipmitool_command(mgmt, ['chassis', 'power', 'status'])
    except Exception as e:
        message = "Remote IPMI failed for mgmt '{mgmt}'".format(mgmt=mgmt)
        logger.exception(message)
        raise RuntimeError('{msg}: {error}'.format(msg=message, error=e))

    if not status.startswith('Chassis Power is'):
        raise RuntimeError('Unexpected chassis status: {status}'.format(status=status))


def get_phabricator_client():
    """Return a Phabricator client instance."""
    parser = configparser.ConfigParser()
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
    """Add a comment on a Phabricator task.

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
    """Resolve and return a DNS record for name. Return None if the target hostname is invalid."""
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


def get_puppet_ca_master():
    """Return the FQDN of the current CA master for the Puppet CA."""
    with open('/etc/puppet/puppet.conf', 'r') as puppet_conf:
        for line in puppet_conf.readlines():
            if not line.startswith('ca_server ='):
                continue

            try:
                ca_master = line.split()[2].strip()
                break
            except IndexError:
                raise RuntimeError(('Unable to extract Puppet CA master from '
                                    'puppet.conf: {line}').format(line=line))
        else:
            raise RuntimeError('Unable to find ca_server setting in puppet.conf')

    if not is_hostname_valid(ca_master):
        raise RuntimeError(
            'Puppet CA master host does not have a valid hostname: {host}'.format(host=ca_master))

    return ca_master


def ensure_ipmi_password():
    """Get the IPMI password from the environment or ask for it and set/return it."""
    ipmi_password = os.getenv('IPMI_PASSWORD')

    if ipmi_password is None:
        logger.info('Missing IPMI_PASSWORD in the environment, asking for it')
        # Ask for a password, raise exception if not a tty
        ipmi_password = getpass.getpass(
            prompt='IPMI Password: ', stream=safe_stdout)
        os.environ['IPMI_PASSWORD'] = ipmi_password
    else:
        logger.info('Found IPMI_PASSWORD in the environment, using it')

    if len(ipmi_password) == 0:
        raise RuntimeError('Empty IPMI_PASSWORD, please verify it')

    return ipmi_password


def get_option_from_name(key):
    """Convert an ArgumentParser key back to command line option.

    Arguments:
    key -- the key to convert
    """
    return '--{key}'.format(key=key.replace('_', '-'))


def get_reimage_host_command(host, mgmt, args):
    """Return the command to launch the reimage script on one host given the parameters.

    Arguments:
    host -- the FQDN of the host to reimage
    mgmt -- the FQDN of the management console for the host
    args -- the ArgumentParser instance with the options to apply
    """
    command_args = ['/usr/local/sbin/wmf-auto-reimage-host']
    args_dict = vars(args)
    # Add boolean command line arguments
    for key in ('debug', 'no_reboot', 'no_verify', 'no_downtime', 'no_pxe', 'new', 'apache',
                'conftool'):
        if args_dict[key]:
            command_args.append(get_option_from_name(key))

    # Add command line arguments with values
    # The --phab-task-id options is skipped because the main script already takes care
    # of upgrading Phabricator
    for key in ('conftool_value', 'mask'):
        if args_dict[key] is not None:
            command_args.append(get_option_from_name(key))
            command_args.append(args_dict[key])

    command_args.append(host)
    command_args.append(mgmt)
    return command_args


def run_cumin(label, hosts_query, commands, timeout=30, installer=False, ignore_exit=False):
    """Run a remote command via Cumin.

    Arguments:
    label       -- label to identify the caller in messages and logs
    hosts_query -- the query for the hosts selection to pass to cumin
    commands    -- the list of commands to be executed
    timeout     -- a timeout in seconds for each command. [optional, default: 30]
    installer   -- whether the host will reboot into the installer or not,
    """
    if installer:
        config = cumin_config_installer
        if 'SSH_AUTH_SOCK' in os.environ:
            del os.environ['SSH_AUTH_SOCK']
    else:
        config = cumin_config

    hosts = query.Query(config).execute(hosts_query)
    target = transports.Target(hosts)
    worker = transport.Transport.new(config, target)

    ok_codes = None
    if ignore_exit:
        ok_codes = []
    worker.commands = [transports.Command(command, timeout=timeout, ok_codes=ok_codes)
                       for command in commands]
    worker.handler = 'async'
    exit_code = worker.execute()

    if exit_code != 0:
        raise RuntimeError('Failed to {label}'.format(label=label))

    return exit_code, worker


def validate_hosts(hosts, no_raise=False):
    """Check that the given hosts have a signed certificate on the Puppet master.

    Raise RuntimeError if any host is not valid and no_raise is False

    Arguments:
    hosts    -- the list of hosts to depool
    no_raise -- do not raise on failure, just log [optional, default: False]

    Returns:
    True if the given hostnames have a signed certificate on the Puppet master, False otherwise
    """
    if len(hosts) == 1:
        command = "puppet cert list '{host}' 2> /dev/null".format(host=hosts[0])
    else:
        command = "puppet cert list --all 2> /dev/null | egrep '({hosts})'".format(
            hosts='|'.join(hosts))

    exit_code, worker = run_cumin(
        'validate_hosts', get_puppet_ca_master(), [command], ignore_exit=True)

    missing = hosts[:]
    output = None
    for _, output in worker.get_results():
        for host in hosts:
            if '+ "{host}"'.format(host=host) in output.message().decode():
                missing.remove(host)

    if missing:
        output_string = '' if output is None else output.message().decode()

        message = ('Signed cert on Puppet not found for hosts {missing} '
                   'and no_raise={no_raise}:\n{output}').format(
                       missing=missing, output=output_string, no_raise=no_raise)

        if no_raise:
            logger.warning(message)
            return False
        else:
            raise RuntimeError(message)
    else:
        if len(hosts) == 1:
            print_line('Validated host', host=hosts[0])
        else:
            print_line('Validated hosts: {hosts}'.format(hosts=hosts))

    return True


def icinga_downtime(host, user, phab_task, title='wmf-auto-reimage'):
    """Set downtime on Icinga for a host.

    Arguments:
    host      -- the hosts to set downtime for
    user      -- the user that is executing the command
    phab_task -- the related Phabricator task ID (i.e. T12345)
    """
    command = ("icinga-downtime -h '{host}' -d 14400 -r "
               "'{title}: user={user} phab_task={phab_task}'").format(
                   host=host.split('.')[0], title=title, user=user, phab_task=phab_task)

    icinga_host = resolve_dns(ICINGA_DOMAIN, 'CNAME')
    run_cumin('icinga_downtime', icinga_host, [command])

    print_line('Downtimed on Icinga', host=host)


def conftool_depool(host, pooled='inactive'):
    """Depool a host via conftool and return its previous status.

    Arguments:
    host   -- the host to depool
    pooled -- the conftool value for the pooled key. [default: inactive]
    """
    conftool = Confctl('node')
    previous = defaultdict(list)
    for obj in conftool.get(name=host):
        obj.tags['name'] = host
        previous[obj.pooled].append(obj.tags)

    conftool.update({'pooled': pooled}, name=host)
    for obj in conftool.get(name=host):
        if obj.pooled != pooled:
            raise RuntimeError('Unable to set/pooled={pooled} for: {obj}'.format(
                pooled=pooled, obj=obj))

    print_line('Depooled via conftool, previous state was: {previous}'.format(previous=previous),
               host=host)
    return previous


def disable_puppet(hosts, message):
    run_cumin('disable_puppet', ','.join(hosts), ["disable-puppet '{}'".format(message)])


def enable_puppet(hosts, message):
    run_cumin('enable_puppet', ','.join(hosts), ["enable-puppet '{}'".format(message)])


def run_puppet(hosts, no_raise=False):
    """Run Puppet on the given hosts

    Arguments:
    hosts    -- the list of hosts where to run Puppet
    no_raise -- do not raise exception on failure, just log it
    """
    try:
        run_cumin('run_puppet', ','.join(hosts), ['run-puppet-agent -q'], timeout=600)
        message = 'Puppet run completed'
    except RuntimeError:
        if no_raise:
            message = 'Puppet run failed (but no_raise=True)'
        else:
            raise

    if len(hosts) == 1:
        print_line(message, host=hosts[0])
    else:
        print_line('{message} on hosts: {hosts}'.format(message=message, hosts=hosts))


def puppet_check_cert_to_sign(host, fingerprint):
    """Check if on the puppetmaster there is a new certificate to sign for the given host.

    Return 0 if there is a pending certificate to be signed, 1 if there isn't and 2 if the
    certificate is already signed.

    Arguments:
    host        -- the host to check for a certificate pending signing.
    fingerprint -- the fingerprint of the certificate to validate. If set to CERT_DESTROY, destroy
                   a pending CSR.
    """
    list_command = "puppet cert list '{host}' 2> /dev/null".format(host=host)
    puppetmaster_host = get_puppet_ca_master()

    try:
        _, worker = run_cumin(
            'puppet_check_cert_to_sign', puppetmaster_host, [list_command])
    except RuntimeError:
        return 1

    if fingerprint == CERT_DESTROY:  # Remove a pending CSR
        remove_command = 'puppet ca destroy {host}'.format(host=host)
        run_cumin('puppet_check_cert_to_sign', puppetmaster_host, [remove_command])
        return 1

    for _, output in worker.get_results():
        message = output.message().decode()
        if host in message:
            cert_line = message
            break
    else:
        cert_line = ''

    if (cert_line.startswith('  "{host}"'.format(host=host)) and
            (fingerprint is None or fingerprint in cert_line)):
        return 0
    elif (cert_line.startswith('+ "{host}"'.format(host=host)) and
          (fingerprint is None or fingerprint in cert_line)):
        print_line('Puppet cert already signed', host=host)
        return 2
    else:
        raise RuntimeError('Unable to find cert to sign in: {line}'.format(line=cert_line))


def puppet_remove_local_cert(host, installer=False):
    """Delete the local Puppet certificate.

    Arguments:
    host      -- the host where to delete the local certificate.
    installer -- whether to run the command with the installer key or standard Cumin
                 key. [optional, default: False]
    """
    run_cumin('puppet_remove_local_cert', host, ['rm -rf /var/lib/puppet/ssl'], installer=installer)


def puppet_wait_cert_and_sign(host, fingerprint):
    """Poll the puppetmaster looking for a new key to sign for the given host.

    Return False if the Puppet certificate is already signed, True otherwise.

    Arguments:
    host        -- the host to monitor for a complete Puppet run
    fingerprint -- the certificate fingerprint to validate
    """
    sign_command = "puppet cert sign '{host}'".format(host=host)
    puppetmaster_host = get_puppet_ca_master()
    start = datetime.utcnow()
    timeout = 7200  # 2 hours
    retries = 0

    print_line('Polling until a Puppet sign request appears', host=host)
    while True:
        retries += 1
        logger.debug('Waiting for Puppet cert to sign ({retries})'.format(retries=retries))
        if retries % WATCHER_LOG_LOOPS == 0:
            print_line('Still waiting for Puppet cert to sign after {min} minutes'.format(
                min=(retries * WATCHER_LONG_SLEEP) // 60.0), host=host)

        check_cert = puppet_check_cert_to_sign(host, fingerprint)
        if check_cert == 0:  # Found Puppet cert to sign
            break
        elif check_cert == 1:  # Puppet cert to sign still missing
            if (datetime.utcnow() - start).total_seconds() > timeout:
                logger.error('Timeout reached')
                raise RuntimeError('Timeout reached')

            time.sleep(WATCHER_LONG_SLEEP)
            continue
        elif check_cert == 2:  # Puppet cert already signed
            return False
        else:  # Should never happen
            raise RuntimeError('Unable to check Puppet certificate status on puppetmaster')

    _, worker = run_cumin('puppet_wait_cert_and_sign', puppetmaster_host, [sign_command])
    for _, output in worker.get_results():
        if fingerprint in output.message().decode():
            break
    else:
        print_line('Expected fingerprint {fingerprint} not found in signing message:\n{msg}'.format(
            fingerprint=fingerprint, msg=output.message().decode()), host=host)
        puppet_remove_host(host)
        print_line('Restart Puppetmasters ASAP!!!')
        raise RuntimeError('Aborting due to puppet cert fingerprint mismatch')

    print_line('Signed Puppet cert', host=host)
    validate_hosts([host])

    return True


def puppet_generate_cert(host):
    """Run the Puppet agent once to generate the cert and the CSR, return its fingerprint.

    Arguments:
    host -- the FQDN of the host to run puppet on
    """
    _, worker = run_cumin('puppet_generate_certs', host, ['puppet agent --test --color=false'],
                          installer=True, ignore_exit=True, timeout=300)

    for _, output in worker.get_results():
        for line in output.message().decode().splitlines():
            if 'Certificate Request fingerprint' in line:
                fingerprint = line.split()[-1]
                print_line(
                    'Puppet CSR generated, fingerprint is: {f}'.format(f=fingerprint), host=host)
                return fingerprint

    raise RuntimeError(
        'Unable to find certificate fingerprint in:\n{msg}'.format(msg=output.message().decode()))


def detect_init_system(host):
    """Detect which init system the host is running and return it.

    It use the installer key for Cumin.

    Arguments:
    host      -- the FQDN of the host to check
    """
    _, worker = run_cumin('detect_init', host, ['ps --no-headers -o comm 1'], installer=True)
    for _, output in worker.get_results():
        init_system = output.message().decode()
        break

    return init_system


def puppet_first_run(host):
    """Disable Puppet service, enable Puppet agent and run it for the first time.

    Arguments:
    host -- the FQDN of the host for which the Puppet certificate has to be revoked
    """
    commands = []
    if detect_init_system(host) == 'systemd':
        commands += ['systemctl stop puppet.service',
                     'systemctl reset-failed puppet.service || true']

    commands += [
        'puppet agent --enable',
        ('puppet agent --onetime --no-daemonize --verbose --no-splay --show_diff '
         '--ignorecache --no-usecacheonfailure')]

    print_line('Started first puppet run (sit back, relax, and enjoy the wait)', host=host)
    run_cumin('puppet_first_run', host, commands, timeout=10800, installer=True)
    print_line('First Puppet run completed', host=host)


def puppet_remove_host(host):
    """Remove a host from Puppet, cleaning certificate and facts.

    Arguments:
    host -- the FQDN of the host for which the Puppet certificate has to be revoked
    """
    base_commands = (
        "puppet node clean '{host}'",
        "puppet node deactivate '{host}'",
        "! puppet cert list '{host}'",  # Ensure removed
    )
    commands = [command.format(host=host) for command in base_commands]
    run_cumin('remove_from_puppet', get_puppet_ca_master(), commands)
    print_line('Removed from Puppet', host=host)


def debmonitor_remove_host(host):
    """Remove a host from Debmonitor.

    Arguments:
    host -- the FQDN of the host to remove from Debmonitor
    """
    response = requests.delete(
        DEBMONITOR_URL.format(host=host), cert=(DEBMONITOR_CERT, DEBMONITOR_KEY))
    if response.status_code == requests.codes['no_content']:
        print_line('Removed from Debmonitor', host=host)
    else:
        print_line('WARNING: Unable to remove from Debmonitor, got: {code}'.format(
            code=response.status_code), host=host, level=logging.WARNING)


def ipmitool_command(mgmt, ipmi_command):
    """Run an ipmitool command for a remote host.

    Arguments:
    mgmt         -- the FQDN of the management interface of the host to target
    ipmi_command -- a list with the IPMI command to execute split in its components
    """
    ensure_ipmi_password()
    command = ['ipmitool', '-I', 'lanplus', '-H', mgmt, '-U', 'root', '-E'] + ipmi_command
    logger.info('Running IPMI command: {command}'.format(command=command))
    return subprocess.check_output(command).decode()


def set_pxe_boot(host, mgmt, retries=0):
    """Force PXE for the next boot and verify that the setting was applied, retry on failure.

    This function recursively calls itself on failure, for a maximum of 3 retries..

    Arguments:
    host    -- the host to set to boot from PXE
    mgmt    -- the management interface of the host
    retries -- a integer to keep track of nested retries. It should not be set by the caller but
               only internally for the recursive calls. [optional, default: 0]
    """
    set_pxe = ipmitool_command(mgmt, ['chassis', 'bootdev', 'pxe']).rstrip('\n')
    print_line(set_pxe, host=host)
    bootparams = ipmitool_command(mgmt, ['chassis', 'bootparam', 'get', '5'])

    for line in bootparams.splitlines():
        if 'Boot Device Selector' not in line:
            continue

        boot = line.split(':')[1].strip()
        if boot == 'Force PXE':
            break  # Command succeeded
        else:
            print_line('({retries}) Wrong boot device, expected Force PXE, got: {line}'.format(
                retries=retries, line=line), host=host)

            if retries < 2:
                time.sleep(WATCHER_LOG_LOOPS)
                set_pxe_boot(host, mgmt, retries=retries+1)

    else:
        if retries == 0:
            # We're on the first call of the function, after all the eventual recursive calls
            print_line(('WARNING: unable to verify that PXE was set, the host might reboot in the '
                        'current OS'), host=host, level=logging.WARNING)


def check_bios_bootparams(host, mgmt):
    """Check if the BIOS boot parameters are back to normal values, print a warning otherwise.

    Arguments:
    host -- the host to check
    mgmt -- the management interface of the host
    """
    bootparams = ipmitool_command(mgmt, ['chassis', 'bootparam', 'get', '5'])

    for line in bootparams.splitlines():
        if 'Boot parameter data' not in line:
            continue

        bitmask = line.split(':')[1].strip()
        if bitmask == '0000000000':
            break

    else:
        print_line(('WARNING: unable to verify that BIOS boot parameters are back to normal, got:\n'
                    '{params}').format(params=bootparams), host=host, level=logging.WARNING)


def wait_puppet_run(host, start=None):
    """Wait that a Puppet run is completed on the given host.

    Arguments:
    host  -- the host to monitor for a complete Puppet run
    start -- a datetime object to compare with Puppet last run
             [optional, default: utcnow()]
    """
    if start is None:
        start = datetime.utcnow()

    timeout = 7200  # 2 hours
    retries = 0
    # TODO: remove temporary redirect to /dev/null to avoid the deprecation warning
    command = ("source /usr/local/share/bash/puppet-common.sh 2> /dev/null && last_run_success && "
               "awk /last_run/'{ print $2 }' \"${PUPPET_SUMMARY}\"")

    print_line('Polling the completion of a Puppet run', host=host)
    while True:
        retries += 1
        logger.debug('Waiting for Puppet ({retries})'.format(retries=retries))
        if retries % WATCHER_LOG_LOOPS == 0:
            print_line(('Still waiting for a succesful Puppet run '
                        'after {min} minutes.'
                        'Either it has not finished yet or the puppet run '
                        'had errors. You may have to fix the puppet role '
                        'or reinstall with spare::system first. '
                        'Check the log file. The path to it was '
                        'printed at the start of the script.').format(
                       min=(retries * WATCHER_LONG_SLEEP) // 60.0), host=host)

        try:
            exit_code, worker = run_cumin('wait_puppet_run', host, [command])
            for _, output in worker.get_results():
                last_run = datetime.utcfromtimestamp(float(output.message().decode()))

            if last_run > start:
                break
        except RuntimeError:
            pass

        if (datetime.utcnow() - start).total_seconds() > timeout:
            logger.error('Timeout reached')
            raise RuntimeError

        time.sleep(WATCHER_LONG_SLEEP)

    print_line('Puppet run checked', host=host)


def reboot_host(host):
    """Reboot the given host.

    Arguments:
    host  -- the host to be rebooted
    """
    run_cumin('reboot_host', host, ['nohup reboot &> /dev/null & exit'])
    print_line('Rebooted host', host=host)


def wait_reboot(host, start=None, installer_key=False, debian_installer=False):
    """Wait for the given host to be back online after a reboot.

    Arguments:
    host             -- the host to monitor
    start            -- a datetime object to compare with Puppet last run
                        [optional, default: utcnow()]
    installer_key    -- whether to use the installer SSH key to connect
    debian_installer -- whether the reboot will be into the debian-installer
    """
    if start is None:
        start = datetime.utcnow()
    check_start = datetime.utcnow()
    timeout = 3600  # 1 hour
    retries = 0

    while True:
        retries += 1
        logger.debug('Waiting for reboot ({retries})'.format(retries=retries))
        if retries % WATCHER_LOG_LOOPS == 0:
            print_line('Still waiting for reboot after {min} minutes'.format(
                min=(retries * WATCHER_LONG_SLEEP) // 60.0), host=host)

        try:
            check_uptime(host, maximum=(datetime.utcnow() - start).total_seconds(),
                         installer=installer_key)
            break
        except RuntimeError:
            if (datetime.utcnow() - check_start).total_seconds() > timeout:
                logger.error('Timeout reached')
                raise RuntimeError('Timeout reached')

        time.sleep(WATCHER_LONG_SLEEP)

    msg = ''
    if debian_installer:
        msg = ' (Debian installer)'
    print_line('Host up{msg}'.format(msg=msg), host=host)


def check_uptime(host, minimum=0, maximum=None, installer=False):
    """Check that the uptime is between limits: minimum <= uptime <= maximum.

    Arguments:
    host      -- the host where to check the uptime
    minimum   -- uptime has to be greater than these seconds
                 [optional, default: 0]
    maximum   -- uptime has to be less than these seconds [optional]
    installer -- whether to run the command with the installer key or standard Cumin
                 key. [optional, default: False]
    """
    try:
        exit_code, worker = run_cumin(
            'check_uptime', host, ['cat /proc/uptime'], installer=installer)
        for _, output in worker.get_results():
            uptime = float(output.message().decode().strip().split()[0])
    except ValueError:
        message = "Unable to determine uptime of host '{host}': {uptime}".format(
            host=host, uptime=output.message().decode())
        logger.error(message)
        raise RuntimeError(message)

    if uptime < minimum or (maximum is not None and uptime > maximum):
        message = ("Uptime for host '{host}' not within expected limits: "
                   "{minimum} <= {uptime} <= {maximum}").format(
                       host=host, minimum=minimum, uptime=uptime, maximum=maximum)
        logger.error(message)
        raise RuntimeError(message)

    print_line('Uptime checked', host=host)


def run_apache_fast_test(host):
    """Run apache-fast-test from the active deployment_server (deploy1001) on the given hosts.

    Arguments:
    host -- the host against which the apache fast test must be executed
    """
    command = 'apache-fast-test /usr/local/share/apache-tests/baseurls {host}'.format(host=host)
    deployment_host = resolve_dns(DEPLOYMENT_DOMAIN, 'CNAME')
    try:
        run_cumin('run_apache_fast_test', deployment_host, [command], timeout=120)
        print_line('Successfully tested with Apache fast-test', host=host)
    except RuntimeError:
        # We don't want to fail upon this failure, this is just a validation test
        # for the user.
        print_line('WARNING: failed to run Apache fast-test, check cumin logs', host=host,
                   level=logging.WARNING)


def print_repool_message(previous, rename_from=None, rename_to=None):
    """Print a message with the commands to repool the depooled hosts.

    Arguments:
    previous    -- a dictionary with state: [list of tags dictionaries] for each state
    rename_from -- in case of host renaming, rename tags with this FQDN to the value of rename_to
    rename_to   -- in case of host renaming, rename tags with rename_from value to this FQDN
    """
    if previous is None:
        print_line('Unable to provide conftool repool command, previous state is unknown')
        return

    base_command = "sudo -i confctl select '{tags}' set/pooled={state}"
    commands = []
    is_rename = rename_from is not None and rename_to is not None

    for state, tags_list in previous.items():
        for tags in tags_list:
            items = []
            for key, value in tags.items():
                if is_rename and value == rename_from:
                    value = rename_to
                items.append('='.join((key, value)))

            selector = ','.join(items)
            commands.append(base_command.format(tags=selector, state=state))

    rename = ''
    if is_rename:
        rename = ' (with the new hostname)'
    message = ('To set back the conftool status to their previous values{rename} run:\n'
               '{repool}').format(rename=rename, repool='\n'.join(commands))

    print_line(message)


def get_phabricator_post_message(retcodes):
    """Return the result message to append to the Phabricator task.

    Arguments:
    retcodes -- a dictionary with retcode as keys and a list of hosts as values
    """
    successful = []
    failed = []
    for retcode, hosts in retcodes.items():
        if retcode == 0:
            successful += hosts
        else:
            failed += hosts

    if failed:
        result = PHAB_COMMENT_POST_FAILED.format(failed=failed)
    else:
        result = PHAB_COMMENT_POST_SUCCESS

    message = '{common}\n{result}'.format(
        common=PHAB_COMMENT_POST.format(hosts=hosts), result=result)

    return message


def mask_systemd_services(host, services):
    """Mask the provided services on the host.

    Arguments:
    host     -- the host on which to mask the services
    services -- a list with the names of the services, without the .service suffix
    """
    for service in services:
        run_cumin('mask_systemd_service', host,
                  ['systemctl mask {service}.service'.format(service=service)], installer=True)

    print_line('Masked systemd units: {units}'.format(units=', '.join(services)), host=host)


def print_unmask_message(host, services):
    """Print and log the commands to execute to unmask the masked systemd services.

    Arguments:
    services -- a list with the names of the services, without the .service suffix
    """
    commands = []
    for service in services:
        commands.append('systemctl unmask {service}.service'.format(service=service))

    print_line('To unmask the masked services run:\n{cmds}'.format(cmds='\n'.join(commands)),
               host=host)
