'''
Run git deployment commands
'''

import re
import urllib

def sync_all():
    '''
    Sync all repositories. If a repo doesn't exist on target, clone as well.

    CLI Example::

	salt -G 'cluster:appservers' deploy.sync_all
    '''
    repourls = __pillar__.get('repo_urls')
    minion_regexes = __pillar__.get('repo_minion_regex')
    site = __salt__['grains.item']('site')
    repourls = repourls[site]
    repolocs = __pillar__.get('repo_locations')
    status = 0

    minion = __grains__.get('id', '')
    for repo,repourl in repourls.items():
        repoloc = repolocs[repo]
	minion_regex = minion_regexes[repo]
        if not re.search(minion_regex,minion):
            continue
        if not __salt__['file.directory_exists'](repoloc + '/.git'):
            __salt__['git.clone'](repoloc,repourl + '/.git')
        else:
            ret = __salt__['deploy.checkout'](repo)
        ret = __salt__['deploy.checkout'](repo)
        if ret != 0:
            status = 1

    return status

def fetch(repo):
    '''
    Call a fetch for the specified repo

    CLI Example::

	salt -G 'cluster:appservers' deploy.fetch 'slot0'
    '''
    site = __salt__['grains.item']('site')
    repourls = __pillar__.get('repo_urls')
    repourls = repourls[site]
    repourl = repourls[repo]
    repolocs = __pillar__.get('repo_locations')
    repoloc = repolocs[repo]

    cmd = '/usr/bin/git remote set-url origin %s' % repourl + "/.git"
    __salt__['cmd.retcode'](cmd,repoloc)

    cmd = '/usr/bin/git fetch'

    return __salt__['cmd.retcode'](cmd,repoloc)

def checkout(repo,reset=False):
    '''
    Checkout the current deployment tag. Assumes a fetch has been run.

    CLI Example::

	salt -G 'cluster:appservers' deploy.checkout 'slot0'
    '''
    #TODO: replace the cmd.retcode calls with git module calls, where appropriate
    site = __salt__['grains.item']('site')
    repourls = __pillar__.get('repo_urls')
    repourls = repourls[site]
    repourl = repourls[repo]
    repolocs = __pillar__.get('repo_locations')
    repoloc = repolocs[repo]
    sed_lists = __pillar__.get('repo_regex')
    sed_list = sed_lists[repo]
    checkout_submodules = __pillar__.get('repo_checkout_submodules')
    checkout_submodules = checkout_submodules[repo]
    module_calls = __pillar__.get('repo_checkout_module_calls')
    module_calls = module_calls[repo]
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

    if reset:
        # User requested we hard reset the repo to the tag
        cmd = '/usr/bin/git reset --hard tags/%s' % (tag)
        ret = __salt__['cmd.retcode'](cmd,repoloc)
        if ret != 0:
            return 20
    else:
        cmd = '/usr/bin/git describe --always --tag'
        current_tag = __salt__['cmd.run'](cmd,repoloc)
        current_tag = current_tag.strip()
        if current_tag == tag:
            return 0

    # Switch to the tag defined in the server's .deploy file
    cmd = '/usr/bin/git checkout --force --quiet tags/%s' % (tag)
    ret = __salt__['cmd.retcode'](cmd,repoloc)
    if ret != 0:
        return 30

    # There's a bug with using booleans in pillars, so for now
    # we're matching against an explicit True string.
    if checkout_submodules == "True":
        # Transform .gitmodules file based on defined seds
        for sed in sed_list:
            for before,after in sed.items():
                after = after.replace('__REPO_URL__',repourl)
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
            ret = 50

    # Call modules on the repo's behalf ignore the return on these
    for call in module_calls:
        __salt__[call](repo)
    return 0
