'''
Wrapper for salt commands to see which minions failed
'''

import salt.cli.key
import salt.client
import re

# TODO: make this configurable
reg = 'mw*.eqiad.wmnet'

def fetch(repo):
    '''
    Fetch from a master, for the specified repo
    '''
    client = salt.client.LocalClient(__opts__['conf_file'])
    cmd = 'deploy.fetch'
    arg = (repo,)
    minions = {}
    ret = client.cmd_cli(reg, cmd, expr_form='pcre', arg=arg, timeout=120)
    for minion in ret:
        minions = dict(minions.items() + minion.items())
    key = salt.cli.key.Key(__opts__)
    keys = key._keys('acc')
    return report(minions,keys)

def checkout(repo):
    '''
    Fetch from a master, for the specified repo
    '''
    client = salt.client.LocalClient(__opts__['conf_file'])
    cmd = 'deploy.checkout'
    arg = (repo,)
    minions = {}
    ret = client.cmd_cli(reg, cmd, expr_form='pcre', arg=arg, timeout=120)
    for minion in ret:
        minions = dict(minions.items() + minion.items())
    key = salt.cli.key.Key(__opts__)
    keys = key._keys('acc')
    return report(minions,keys)

def report(minions,keys):
    success = []
    nochanges = []
    didnotrun = []
    fail = {}
    for minion,ret in sorted(minions.items()):
        if ret == {}:
            nochanges.append(minion)
            continue
        if not isinstance(ret, dict):
            fail[minion] = ret
            continue
        if 'ret' in ret.keys():
            if ret['ret'] == 0:
                success.append(minion)
            else:
                if 'comment' in ret.keys():
                    fail[minion] = ret['comment']
                else:
                    fail[minion] = ret
    for minion in sorted(keys - set(minions.keys())):
        if re.search(reg,minion):
            didnotrun.append(minion)
    report = [{'success': success}, {'nochanges': nochanges}, {'didnotrun': didnotrun}, {'fail': fail}]
    print report
    return report
