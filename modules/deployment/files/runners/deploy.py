'''
Authn wrapper for deployment peer calls
'''

import salt.key
import salt.client
import re
import yaml


def fetch(repo):
    '''
    Fetch from a master, for the specified repo
    '''
    grain = "deployment_target:" + repo
    client = salt.client.LocalClient(__opts__['conf_file'])
    cmd = 'deploy.fetch'
    # comma in the tuple is a workaround for a bug in salt
    arg = (repo,)
    client.cmd(grain, cmd, expr_form='grain', arg=arg, timeout=1,
               ret='deploy_redis')
    print "Fetch completed"


def checkout(repo, reset=False):
    '''
    Checkout from a master, for the specified repo
    '''
    grain = "deployment_target:" + repo
    client = salt.client.LocalClient(__opts__['conf_file'])
    cmd = 'deploy.checkout'
    arg = (repo, reset)
    client.cmd(grain, cmd, expr_form='grain', arg=arg, timeout=1,
               ret='deploy_redis')
    print "Checkout completed"


def restart(repo, batch='10%'):
    '''
    Restart the service associated with this repo. If no service is associated
    this call will do nothing.
    '''
    grain = "deployment_target:" + repo
    client = salt.client.LocalClient(__opts__['conf_file'])
    cmd = 'deploy.restart'
    # comma in the tuple is a workaround for a bug in salt
    arg = (repo,)
    ret = []
    for data in client.cmd_batch(grain, cmd, expr_form='grain', arg=arg,
                                 timeout=60, ret='deploy_redis', batch=batch):
        ret.append(data)
    print "Restart completed"
    return ret
