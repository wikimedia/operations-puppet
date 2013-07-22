'''
Authn wrapper for deployment peer calls
'''

import salt.key
import salt.client
import re
import yaml


def __get_conf(repo, key):
    try:
        config = yaml.load(file('/etc/salt/deploy_runner.conf', 'r'))
        return config[key][repo]
    except IOError:
        return ''
    except yaml.YAMLError:
        return ''
    except KeyError:
        return ''


def fetch(repo):
    '''
    Fetch from a master, for the specified repo
    '''
    grain = __get_conf(repo, 'deployment_repo_grains')
    if not grain:
        return "No grain defined for this repo."
    grain = "deployment_target:" + grain
    client = salt.client.LocalClient(__opts__['conf_file'])
    cmd = 'deploy.fetch'
    # comma in the tuple is a workaround for a bug in salt
    arg = (repo,)
    client.cmd(grain, cmd, expr_form='grain', arg=arg, timeout=30,
               ret='deploy_redis')
    print "Fetch completed"


def checkout(repo, grain, reset=False):
    '''
    Checkout from a master, for the specified repo
    '''
    grain = __get_conf(repo, 'deployment_repo_grains')
    if not grain:
        return "No grain defined for this repo."
    grain = "deployment_target:" + grain
    client = salt.client.LocalClient(__opts__['conf_file'])
    cmd = 'deploy.checkout'
    arg = (repo, reset)
    client.cmd(grain, cmd, expr_form='grain', arg=arg, timeout=30,
               ret='deploy_redis')
    print "Checkout completed"
