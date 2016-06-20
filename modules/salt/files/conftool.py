# -*- coding: utf-8 -*-
'''
Execute conftool pool/depool actions, or fetch info

Copyright (c) 2016 Giuseppe Lavagetto, Wikimedia Foundation Inc.

This module is distributed under the same license as SaltStack -
see https://github.com/saltstack/salt/blob/develop/LICENSE
'''

from __future__ import absolute_import
import logging
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


class _Conftool(object):

    def __init__(self, service=None):
        self.service = service

    @property
    def select_string(self):
        select_string = 'dc=%s,cluster=%s,name=%s' % (
            __grains__['site'],
            __grains__['cluster'],
            __grains__['fqdn'],
        )
        if self.service is not None:
            select_string += ',%s' % self.service

    def run(self, action):
        cmd = 'confctl --quiet select %s %s' % (self.select_string, action)
        return __salt__['cmd.run'](cmd)



def status(service=None):
    '''
    Gets the conftool status of all services (or a specific one) for the host.
    The results are returned as they're served from conftool.

    CLI Example:

    .. code-block:: bash

        salt 'cp*' conftool.status

        salt 'cp*' conftool.status service=varnish-fe
    '''
    c = _Conftool(service)
    return c.run('get')


def depool(service=None):
    '''
    Depools the host from all of the services defined, or just a specific one.

    CLI Example:

    .. code-block:: bash

        salt 'cp*' conftool.depool

        salt 'cp*' conftool.depool service=varnish-fe

    '''
    c = _Conftool(service)
    return c.run('set/pooled=no')


def pool(service=None, weight=None):
    '''
    Pools the host from all of the services defined, or just a specific one.
    A weight for the pooling can also be defined.

    CLI Example:

    .. code-block:: bash

        salt 'cp*' conftool.pool

        salt 'cp*' conftool.pool service=varnish-fe weight=10

    '''
    action = 'set/pooled=yes'
    if weight is not None:
        action += ':weight=%d' % int(weight)
    c = _Conftool(service)
    return c.run(action)


def drain(service=None):
    '''
    Drains the host either from all services or a specific one.

    .. code-block:: bash

        salt 'cp*' conftool.drain

        salt 'cp*' conftool.drain service=varnish-fe

    '''
    c = _Conftool(service)
    return c.run('set/weight=0')


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
