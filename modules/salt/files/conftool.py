# -*- coding: utf-8 -*-
'''
Execute conftool pool/depool actions, or fetch info

Copyright (c) 2016 Giuseppe Lavagetto, Wikimedia Foundation Inc.

This module is distributed under the same license as SaltStack -
see https://github.com/saltstack/salt/blob/develop/LICENSE
'''

from __future__ import absolute_import
import logging
import os
from time import sleep

# salt libs
import salt.utils

log = logging.getLogger(__name__)


def __virtual__():
    '''
    Only load if conftool is installed
    '''
    if salt.utils.which('confctl') is None:
        return (False, 'confctl is not installed here')
    return 'conftool'

select_string = 'dc=%s,cluster=%s,name=%s' % (
    __grains__['site'],
    __grains__['cluster'],
    __grains__['fqdn']
)


def status(service=None):
    '''
    Gets the conftool status of all services (or a specific one) for the host.
    The results are returned as they're served from conftool.

    CLI Example:

    .. code-block:: bash

        salt 'cp*' conftool.status

        salt 'cp*' conftool.status service=varnish-fe
    '''
    cmd = 'confctl select "%s' % select_string
    if service is not None:
        cmd += ',service=%s' % service
    cmd += '" get'
    return __salt__['cmd.run'](cmd)


def depool(service=None):
    '''
    Depools the host from all of the services defined, or just a specific one.

    CLI Example:

    .. code-block:: bash

        salt 'cp*' conftool.depool

        salt 'cp*' conftool.depool service=varnish-fe

    '''
    cmd = 'confctl --quiet select "%s' % select_string
    if service is not None:
        cmd += ',service=%s' % service
    cmd += '" set/pooled=no'
    return __salt__['cmd.run'](cmd)


def pool(service=None, weight=None):
    '''
    Depools the host from all of the services defined, or just a specific one.

    CLI Example:

    .. code-block:: bash

        salt 'cp*' conftool.depool

        salt 'cp*' conftool.depool service=varnish-fe

    '''
    cmd = 'confctl --quiet select "%s' % select_string
    if service is not None:
        cmd += ',service=%s' % service
    cmd += '" set/pooled=yes'
    if weight is not None:
        cmd += ':weight=%s' % weight
    return __salt__['cmd.run'](cmd)


def drain(service=None):
    '''
    Drains the host either from all services or a specific one.

    .. code-block:: bash

        salt 'cp*' conftool.drain

        salt 'cp*' conftool.drain service=varnish-fe

    '''
    cmd = 'confctl --quiet select "%s' % select_string
    if service is not None:
        cmd += ',service=%s' % service
    cmd += '" set/weight=0'
    return __salt__['cmd.run'](cmd)


def safe_depool(service=None, delay=10):
    '''
    Safey depools the host by first draining it.
    A specific service to depool can be specified, and a time delay
    between draining and depooling (by default, 10 seconds).

    CLI Example:

    .. code-block:: bash

        salt 'cp*' conftool.safe_depool

        salt 'cp*' conftool.depool service=varnish-fe delay=20

    '''
    drain(service=service)
    sleep(int(delay))
    depool(service=service)


if __name__ == '__main__':
    # When a linter is stupid, you just to make it happy.
    # -- _joe_
    __salt__ = dict()
    __grains__ = dict()
