# -*- coding: utf-8 -*-
'''
Execute puppet routines

Note: this is a tweak/improvement of the latest version of the puppet module
that is shipped by SaltStack.

Additional code (c) 2016 Giuseppe Lavagetto, Wikimedia Foundation Inc.

This module is distributed under the same license as SaltStack -
see https://github.com/saltstack/salt/blob/develop/LICENSE
'''

from __future__ import absolute_import
import datetime
from distutils import version
import json
import logging
import os

# salt libs
import salt.utils
from salt.exceptions import CommandExecutionError

# 3rd party libs
import yaml
import salt.ext.six as six
from salt.ext.six.moves import range


log = logging.getLogger(__name__)


def __virtual__():
    '''
    Only load if puppet is installed
    '''
    unavailable_exes = ', '.join(exe for exe in ('facter', 'puppet')
                                 if salt.utils.which(exe) is None)
    if unavailable_exes:
        return (False,
                ('The puppet execution module cannot be loaded: '
                 '{0} unavailable.'.format(unavailable_exes)))
    else:
        return 'wmfpuppet'


def _format_fact(output):
    try:
        fact, value = output.split(' => ', 1)
        value = value.strip()
    except ValueError:
        fact = None
        value = None
    return (fact, value)


class _Puppet(object):
    '''
    Puppet helper class. Used to format command for execution.
    '''

    def __init__(self):
        '''
        Setup a puppet instance, based on the premis that default usage is to
        run 'puppet agent --test'. Configuration and run states are stored in
        the default locations.
        '''
        self.subcmd = 'agent'
        self.subcmd_args = []  # e.g. /a/b/manifest.pp

        self.kwargs = {'color': 'false'}       # e.g. --tags=apache::server
        self.args = []         # e.g. --noop

        self.useshell = False
        self.puppet_version = __salt__['cmd.run']('puppet --version')
        if self.puppet_version != [] and version.StrictVersion(
                self.puppet_version) >= version.StrictVersion('4.0.0'):
            self.vardir = '/opt/puppetlabs/puppet/cache'
            self.rundir = '/var/run/puppetlabs'
            self.confdir = '/etc/puppetlabs/puppet'
        else:
            self.vardir = '/var/lib/puppet'
            self.rundir = '/var/run/puppet'
            self.confdir = '/etc/puppet'

        self.disabled_lockfile = self.vardir + '/state/agent_disabled.lock'
        self.run_lockfile = self.vardir + '/state/agent_catalog_run.lock'
        self.agent_pidfile = self.rundir + '/agent.pid'
        self.lastrunfile = self.vardir + '/state/last_run_summary.yaml'

    def __repr__(self):
        '''
        Format the command string to executed using cmd.run_all.
        '''
        cmd = 'puppet {subcmd} --vardir {vardir} --confdir {confdir}'.format(
            **self.__dict__
        )

        args = ' '.join(self.subcmd_args)
        args += ''.join(
            [' --{0}'.format(k) for k in self.args]  # single spaces
        )
        args += ''.join([
            ' --{0} {1}'.format(k, v) for k, v in six.iteritems(self.kwargs)]
        )

        return '{0} {1}'.format(cmd, args)

    def arguments(self, args=None):
        '''
        Read in arguments for the current subcommand. These are added to the
        cmd line without '--' appended. Any others are redirected as standard
        options with the double hyphen prefixed.
        '''
        # permits deleting elements rather than using slices
        args = args and list(args) or []

        # match against all known/supported subcmds
        if self.subcmd == 'apply':
            # apply subcommand requires a manifest file to execute
            self.subcmd_args = [args[0]]
            del args[0]

        if self.subcmd == 'agent':
            # no arguments are required
            args.extend([
                'test'
            ])

        # finally do this after subcmd has been matched for all remaining args
        self.args = args


def run(*args, **kwargs):
    '''
    Execute a puppet run and return a dict with the stderr, stdout,
    return code, etc. The first positional argument given is checked as a
    subcommand. Following positional arguments should be ordered with arguments
    required by the subcommand first, followed by non-keyword arguments.
    Tags are specified by a tag keyword and comma separated list of values. --
    http://docs.puppetlabs.com/puppet/latest/reference/lang_tags.html

    CLI Examples:

    .. code-block:: bash

        salt '*' puppet.run
        salt '*' puppet.run tags=basefiles::edit,apache::server
        salt '*' puppet.run agent onetime no-daemonize no-usecacheonfailure \
            no-splay ignorecache
        salt '*' puppet.run debug
        salt '*' puppet.run apply /a/b/manifest.pp modulepath=/a/b/modules \
            tags=basefiles::edit,apache::server
    '''
    puppet = _Puppet()

    # new args tuple to filter out agent/apply for _Puppet.arguments()
    buildargs = ()
    for arg in range(len(args)):
        # based on puppet documentation action must come first. making the same
        # assertion. need to ensure the list of supported cmds here matches
        # those defined in _Puppet.arguments()
        if args[arg] in ['agent', 'apply']:
            puppet.subcmd = args[arg]
        else:
            buildargs += (args[arg],)
    # args will exist as an empty list even if none have been provided
    puppet.arguments(buildargs)

    puppet.kwargs.update(salt.utils.clean_kwargs(**kwargs))

    ret = __salt__['cmd.run_all'](repr(puppet), python_shell=puppet.useshell)
    if ret['retcode'] in [0, 2]:
        ret['retcode'] = 0
    else:
        ret['retcode'] = 1

    return ret


def noop(*args, **kwargs):
    '''
    Execute a puppet noop run and return a dict with the stderr, stdout,
    return code, etc. Usage is the same as for puppet.run.

    CLI Example:

    .. code-block:: bash

        salt '*' puppet.noop
        salt '*' puppet.noop tags=basefiles::edit,apache::server
        salt '*' puppet.noop debug
        salt '*' puppet.noop apply /a/b/manifest.pp tags=apache::server
    '''
    args += ('noop',)
    return run(*args, **kwargs)


def enable(*args, **kwargs):
    """
    Enable puppet on the host. If a message is provided, puppet will be
    enabled only if the message matches the actual disabling message. This is
    done to prevent that a mass enabling (i.e. after testing a risky puppet
    change) could  have undesirable effects (e.g. a host has a temporarily
    modified config or a service is manually disabled during investigation).

    If no message is specified, puppet will be enabled unconditionally

    CLI Examples:

    .. code-block:: bash

        salt '*' wmfpuppet.enable "I am messing with hiera"
        salt '*' wmfpuppet.enable
    """
    puppet = _Puppet()
    try:
        msg = args[0]
    except:
        msg = None

    if not os.path.isfile(puppet.disabled_lockfile):
        log.info("Puppet is not disabled, no reason to enable it")
        return False

    if msg is not None:
        with salt.utils.fopen(puppet.disabled_lockfile, "rb") as fh:
            disabled_data = json.load(fh)
        if msg != disabled_data["disabled_message"]:
            log.warn(
                "Puppet is disabled with message '%s' instead of '%s'",
                disabled_data["disabled_message"],
                msg
            )
            return False
    # No more checks to perform
    try:
        os.remove(puppet.disabled_lockfile)
        return True
    except (IOError, OSError) as e:
        error = "Failed to remove the client lockfile: %s" % e
        log.error(error)
        raise CommandExecutionError(error)


def disable(*args, **kwargs):
    """
    Disable puppet on the host. Note that the reason specified
    will NOT overwrite a preceding disable message. It can be
    safely used in concert with wmfpuppet.enable.

    CLI Example:

    .. code-block:: bash

        salt '*' wmfpuppet.disable "I am messing with hiera"
        salt '*' wmfpuppet.disable
    """
    puppet = _Puppet()
    try:
        msg = args[0]
    except:
        msg = None

    if os.path.isfile(puppet.disabled_lockfile):
        log.info("Puppet is already disabled, not overwriting the reason")
        return False

    with salt.utils.fopen(puppet.disabled_lockfile, 'w') as fh:
        try:
            json.dump({'disabled_message': msg}, fh)
        except (IOError, OSError) as e:
            error = "Failed to write to the client lockfile: %s" % e
            log.error(error)
            raise CommandExecutionError(error)

    return True


def status():
    '''
    .. versionadded:: 2014.7.0

    Display puppet agent status

    CLI Example:

    .. code-block:: bash

        salt '*' puppet.status
    '''
    puppet = _Puppet()

    if os.path.isfile(puppet.disabled_lockfile):
        return 'Administratively disabled'

    if os.path.isfile(puppet.run_lockfile):
        try:
            with salt.utils.fopen(puppet.run_lockfile, 'r') as fp_:
                pid = int(fp_.read())
                os.kill(pid, 0)  # raise an OSError if process doesn't exist
        except (OSError, ValueError):
            return 'Stale lockfile'
        else:
            return 'Applying a catalog'

    if os.path.isfile(puppet.agent_pidfile):
        try:
            with salt.utils.fopen(puppet.agent_pidfile, 'r') as fp_:
                pid = int(fp_.read())
                os.kill(pid, 0)  # raise an OSError if process doesn't exist
        except (OSError, ValueError):
            return 'Stale pidfile'
        else:
            return 'Idle daemon'

    return 'Stopped'


def summary():
    '''
    .. versionadded:: 2014.7.0

    Show a summary of the last puppet agent run

    CLI Example:

    .. code-block:: bash

        salt '*' puppet.summary
    '''

    puppet = _Puppet()

    try:
        with salt.utils.fopen(puppet.lastrunfile, 'r') as fp_:
            report = yaml.safe_load(fp_.read())
        result = {}

        if 'time' in report:
            try:
                result['last_run'] = datetime.datetime.fromtimestamp(
                    int(report['time']['last_run'])).isoformat()
            except (TypeError, ValueError, KeyError):
                result['last_run'] = 'invalid or missing timestamp'

            result['time'] = {}
            for key in ('total', 'config_retrieval'):
                if key in report['time']:
                    result['time'][key] = report['time'][key]

        if 'resources' in report:
            result['resources'] = report['resources']

    except yaml.YAMLError as exc:
        raise CommandExecutionError(
            'YAML error parsing puppet run summary: {0}'.format(exc)
        )
    except IOError as exc:
        raise CommandExecutionError(
            'Unable to read puppet run summary: {0}'.format(exc)
        )

    return result


def plugin_sync():
    '''
    Runs a plugin synch between the puppet master and agent

    CLI Example:
    .. code-block:: bash

        salt '*' puppet.plugin_sync
    '''
    ret = __salt__['cmd.run']('puppet plugin download')

    if not ret:
        return ''
    return ret


def facts(puppet=False):
    '''
    Run facter and return the results

    CLI Example:

    .. code-block:: bash

        salt '*' puppet.facts
    '''
    ret = {}
    opt_puppet = '--puppet' if puppet else ''
    output = __salt__['cmd.run']('facter {0}'.format(opt_puppet))

    # Loop over the facter output and  properly
    # parse it into a nice dictionary for using
    # elsewhere
    for line in output.splitlines():
        if not line:
            continue
        fact, value = _format_fact(line)
        if not fact:
            continue
        ret[fact] = value
    return ret


def fact(name, puppet=False):
    '''
    Run facter for a specific fact

    CLI Example:

    .. code-block:: bash

        salt '*' puppet.fact kernel
    '''
    opt_puppet = '--puppet' if puppet else ''
    ret = __salt__['cmd.run'](
        'facter {0} {1}'.format(opt_puppet, name),
        python_shell=False)
    if not ret:
        return ''
    return ret


if __name__ == '__main__':
    # I can't believe I accept to add this crap
    # just to make pep8 happy.
    # -- _joe_
    __salt__ = dict()
