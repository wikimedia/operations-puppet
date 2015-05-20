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
    deployment_target = "deployment_target:" + repo
    deployment_server = "deployment_server:*"
    targets = "G@{0} and not G@{1}".format(deployment_target, deployment_server)
    client = salt.client.LocalClient(__opts__['conf_file'])
    cmd = 'deploy.fetch'
    # comma in the tuple is a workaround for a bug in salt
    arg = (repo,)
    client.cmd(targets, cmd, expr_form='compound', arg=arg, timeout=1,
               ret='deploy_redis')
    print "Fetch completed"


def checkout(repo, reset=False):
    '''
    Checkout from a master, for the specified repo
    '''
    deployment_target = "deployment_target:" + repo
    deployment_server = "deployment_server:*"
    targets = "G@{0} and not G@{1}".format(deployment_target, deployment_server)
    client = salt.client.LocalClient(__opts__['conf_file'])
    cmd = 'deploy.checkout'
    arg = (repo, reset)
    client.cmd(targets, cmd, expr_form='compound', arg=arg, timeout=1,
               ret='deploy_redis')
    print "Checkout completed"


def restart(repo, batch='10%'):
    '''
    Restart the service associated with this repo. If no service is associated
    this call will do nothing.
    '''
    deployment_target = "deployment_target:" + repo
    deployment_server = "deployment_server:*"
    targets = "G@{0} and not G@{1}".format(deployment_target, deployment_server)
    client = salt.client.LocalClient(__opts__['conf_file'])
    cmd = 'deploy.restart'
    # comma in the tuple is a workaround for a bug in salt
    arg = (repo,)
    ret = []
    for data in client.cmd_batch(targets, cmd, expr_form='compound', arg=arg,
                                 timeout=60, ret='deploy_redis', batch=batch):
        ret.append(data)
    print "Restart completed"
    return ret
