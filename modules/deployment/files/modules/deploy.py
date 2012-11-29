'''
Run git deployment commands
'''

#import salt.pillar
import urllib

def fetch(repo):
    '''
    Call a fetch for the specified repo

    CLI Example::

	salt -G 'cluster:appservers' deploy.fetch 'slot0'
    '''
    repourls = __pillar__.get('repo_urls')
    repourl = repourls[repo]
    repolocs = __pillar__.get('repo_locations')
    repoloc = repolocs[repo]

    cmd = '/usr/bin/git remote set-url origin %s' % repourl + "/.git"
    __salt__['cmd.retcode'](cmd,repoloc)

    cmd = '/usr/bin/git fetch'

    return __salt__['cmd.retcode'](cmd,repoloc)

def checkout(repo):
    '''
    Checkout the current deployment tag. Assumes a fetch has been run.

    CLI Example::

	salt -G 'cluster:appservers' deploy.checkout 'slot0'
    '''
    #TODO: replace the cmd.retcode calls with git module calls, where appropriate
    repolocs = __pillar__.get('repo_locations')
    repoloc = repolocs[repo]
    repourls = __pillar__.get('repo_urls')
    repourl = repourls[repo]
    sed_lists = __pillar__.get('gitmodules_seds')
    sed_list = sed_lists[repo]
    gitmodules = repoloc + '/.gitmodules'

    # Fetch the .deploy file from the server and get the current tag
    deployfile = repourl + '/.deploy'
    f = urllib.urlopen(deployfile)
    deployinfo = f.readlines()
    tag = ''
    for info in deployinfo:
        if info.startswith('tag: '):
            tag = info[5:]
            tag = tag.strip()
    if not tag:
        return 10

    # The last deploy modified .gitmodules, we need to reset it
    #cmd = '/usr/bin/git checkout .gitmodules'
    #ret = __salt__['cmd.retcode'](cmd,repoloc)
    #if ret != 0:
    #    return 20

    # Switch to the tag defined in the server's .deploy file
    cmd = '/usr/bin/git checkout --force --quiet tags/%s' % (tag)
    ret = __salt__['cmd.retcode'](cmd,repoloc)
    if ret != 0:
        return 30

    # Transform .gitmodules file based on defined seds
    for sed in sed_list:
        for before,after in sed.items():
            __salt__['file.sed'](gitmodules, before, after)

    # Sync the .gitmodules config
    cmd = '/usr/bin/git submodule sync'
    ret = __salt__['cmd.retcode'](cmd,repoloc)
    if ret != 0:
        return 40

    # Update the submodules to match this tag
    cmd = '/usr/bin/git submodule update --init'
    ret = __salt__['cmd.retcode'](cmd,repoloc)
    if ret != 0:
        return 50
    else:
        return ret
