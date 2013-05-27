'''
Run git deployment commands
'''

import redis
import time
import re
import urllib


def _get_serv():
    '''
    Return a redis server object
    '''
    deploy_redis = __pillar__.get('deploy_redis')
    serv = redis.Redis(host=deploy_redis['host'],
                       port=deploy_redis['port'],
                       db=deploy_redis['db'])
    return serv


def _check_in(function, repo):
    serv = _get_serv()
    minion = __salt__['grains.item']('id')
    timestamp = time.time()
    # Ensure this repo exist in the set of repos
    serv.sadd('deploy:repos', repo)
    # Ensure this minion exists in the set of minions
    serv.sadd('deploy:{0}:minions'.format(repo), minion)
    if function == "deploy.fetch":
        serv.hset('deploy:{0}:minions:{1}'.format(repo, minion),
                  'fetch_checkin_timestamp', timestamp)
    elif function == "deploy.checkout":
        serv.hset('deploy:{0}:minions:{1}'.format(repo, minion),
                  'checkout_checkin_timestamp', timestamp)


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
    stats = {}

    minion = __grains__.get('id', '')
    for repo, repourl in repourls.items():
        minion_regex = minion_regexes[repo]
        if not re.search(minion_regex, minion):
            continue
        if repo not in stats:
            stats[repo] = {}
        repoloc = repolocs[repo]
        stats[repo]["deploy.fetch"] = __salt__['deploy.fetch'](repo)
        stats[repo]["deploy.checkout"] = __salt__['deploy.checkout'](repo)

    return {'status': status, 'stats': stats}


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
    sed_lists = __pillar__.get('repo_regex')
    sed_list = sed_lists[repo]
    checkout_submodules = __pillar__.get('repo_checkout_submodules')
    checkout_submodules = checkout_submodules[repo]
    gitmodules = repoloc + '/.gitmodules'

    # Fetch repos this repo depends on
    dependencies = __pillar__.get('repo_dependencies')
    try:
        dependencies = dependencies[repo]
    except KeyError:
        dependencies = []
    depstats = []
    for dependency in dependencies:
        depstats.append(__salt__['deploy.fetch'](dependency))

    # Notify the deployment system we started
    _check_in('deploy.fetch', repo)

    # Clone the repo if it doesn't exist yet
    if not __salt__['file.directory_exists'](repoloc + '/.git'):
        cmd = '/usr/bin/git clone %s %s' % (repourl + '/.git', repoloc)
        status = __salt__['cmd.retcode'](cmd)
        if status != 0:
            return {'status': 5, 'repo': repo, 'dependencies': depstats}

    cmd = '/usr/bin/git remote set-url origin %s' % repourl + "/.git"
    __salt__['cmd.retcode'](cmd, repoloc)

    cmd = '/usr/bin/git fetch'
    status = __salt__['cmd.retcode'](cmd, repoloc)
    if status != 0:
        return {'status': 10, 'repo': repo, 'dependencies': depstats}

    cmd = '/usr/bin/git fetch --tags'
    status = __salt__['cmd.retcode'](cmd, repoloc)
    if status != 0:
        return {'status': 20, 'repo': repo, 'dependencies': depstats}

    # There's a bug with using booleans in pillars, so for now
    # we're matching against an explicit True string.
    if checkout_submodules == "True":
        cmd = '/usr/bin/git checkout .gitmodules'
        ret = __salt__['cmd.retcode'](cmd, repoloc)
        if ret != 0:
            return {'status': 30, 'repo': repo, 'dependencies': depstats}
        # Transform .gitmodules file based on defined seds
        for sed in sed_list:
            for before, after in sed.items():
                after = after.replace('__REPO_URL__', repourl)
                __salt__['file.sed'](gitmodules, before, after)

        # Sync the .gitmodules config
        cmd = '/usr/bin/git submodule sync'
        ret = __salt__['cmd.retcode'](cmd, repoloc)
        if ret != 0:
            return {'status': 40, 'repo': repo, 'dependencies': depstats}

        # fetch all submodules and tag for submodules
        cmd = '/usr/bin/git submodule foreach git fetch'
        ret = __salt__['cmd.retcode'](cmd, repoloc)
        if ret != 0:
            return {'status': 50, 'repo': repo, 'dependencies': depstats}

        # fetch all submodules and tag for submodules
        cmd = '/usr/bin/git submodule foreach git fetch --tags'
        ret = __salt__['cmd.retcode'](cmd, repoloc)
        if ret != 0:
            return {'status': 60, 'repo': repo, 'dependencies': depstats}

    cmd = '/usr/bin/git describe --always --tag origin'
    origin_tag = __salt__['cmd.run'](cmd, repoloc)
    origin_tag = origin_tag.strip()

    return {'status': status, 'repo': repo,
            'dependencies': depstats, 'tag': origin_tag}


def checkout(repo, reset=False):
    '''
    Checkout the current deployment tag. Assumes a fetch has been run.

    CLI Example::

        salt -G 'cluster:appservers' deploy.checkout 'slot0'
    '''
    #TODO: replace the cmd.retcode calls with git module calls,
    # where appropriate
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
    depstats = []

    # Notify the deployment system we started
    _check_in('deploy.checkout', repo)

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
        return {'status': 10, 'repo': repo, 'dependencies': depstats}
    # tags are user-input and are used in shell commands, ensure they are
    # only passing alphanumeric.
    if re.match('\W+', tag):
        return {'status': 1, 'repo': repo, 'dependencies': depstats}

    # Checkout repos this repo depends on
    dependencies = __pillar__.get('repo_dependencies')
    try:
        dependencies = dependencies[repo]
    except KeyError:
        dependencies = []
    for dependency in dependencies:
        depstats.append(__salt__['deploy.checkout'](dependency, reset))

    if reset:
        # User requested we hard reset the repo to the tag
        cmd = '/usr/bin/git reset --hard tags/%s' % (tag)
        ret = __salt__['cmd.retcode'](cmd, repoloc)
        if ret != 0:
            return {'status': 20, 'repo': repo, 'dependencies': depstats}
    else:
        cmd = '/usr/bin/git describe --always --tag'
        current_tag = __salt__['cmd.run'](cmd, repoloc)
        current_tag = current_tag.strip()
        if current_tag == tag:
            return {'status': 0, 'repo': repo,
                    'tag': tag, 'dependencies': depstats}

    # Switch to the tag defined in the server's .deploy file
    cmd = '/usr/bin/git checkout --force --quiet tags/%s' % (tag)
    ret = __salt__['cmd.retcode'](cmd, repoloc)
    if ret != 0:
        return {'status': 30, 'repo': repo, 'dependencies': depstats}

    # There's a bug with using booleans in pillars, so for now
    # we're matching against an explicit True string.
    if checkout_submodules == "True":
        # Transform .gitmodules file based on defined seds
        for sed in sed_list:
            for before, after in sed.items():
                after = after.replace('__REPO_URL__', repourl)
                __salt__['file.sed'](gitmodules, before, after)

        # Sync the .gitmodules config
        cmd = '/usr/bin/git submodule sync'
        ret = __salt__['cmd.retcode'](cmd, repoloc)
        if ret != 0:
            return {'status': 40, 'repo': repo, 'dependencies': depstats}

        # Update the submodules to match this tag
        cmd = '/usr/bin/git submodule update --init'
        ret = __salt__['cmd.retcode'](cmd, repoloc)
        if ret != 0:
            return {'status': 50, 'repo': repo, 'dependencies': depstats}

    # Call modules on the repo's behalf ignore the return on these
    for call in module_calls:
        __salt__[call](repo)
    return {'status': 0, 'repo': repo, 'tag': tag, 'dependencies': depstats}
