'''
Run git deployment commands
'''

import redis
import time
import re
import urllib


def _get_redis_serv():
    '''
    Return a redis server object
    '''
    deployment_config = __pillar__.get('deployment_config')
    deploy_redis = deployment_config['redis']
    serv = redis.Redis(host=deploy_redis['host'],
                       port=int(deploy_redis['port']),
                       db=int(deploy_redis['db']))
    return serv


def _check_in(function, repo):
    serv = _get_redis_serv()
    minion = __grains__.get('id')
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


def get_config(repo):
    deployment_config = __pillar__.get('deployment_config')
    config = __pillar__.get('repo_config')
    config = config[repo]
    if 'location' not in config:
        repoloc = '{0}/{1}'.format(deployment_config['parent_dir'], repo)
        config['location'] = repoloc
    site = __grains__.get('site')
    url = deployment_config['servers'][site]
    config['url'] = '{0}/{1}'.format(url, repo)
    if 'submodule_sed_regex' not in config:
        config['submodule_sed_regex'] = {}
    if 'checkout_submodules' not in config:
        config['checkout_submodules'] = 'False'
    if 'dependencies' not in config:
        config['dependencies'] = []
    if 'checkout_module_calls' not in config:
        config['checkout_module_calls'] = []


def sync_all():
    '''
    Sync all repositories. If a repo doesn't exist on target, clone as well.

    CLI Example::

        salt -G 'cluster:appservers' deploy.sync_all
    '''
    repo_config = __pillar__.get('repo_config')
    deployment_target = __grains__.get('deployment_target')
    status = 0
    stats = {}

    for repo, config in repo_config.items():
        if config['grain'] not in deployment_target:
            continue
        if repo not in stats:
            stats[repo] = {}
        stats[repo]["deploy.fetch"] = __salt__['deploy.fetch'](repo)
        stats[repo]["deploy.checkout"] = __salt__['deploy.checkout'](repo)

    return {'status': status, 'stats': stats}


def fetch(repo):
    '''
    Call a fetch for the specified repo

    CLI Example::

        salt -G 'cluster:appservers' deploy.fetch 'slot0'
    '''
    config = get_config(repo)
    gitmodules = config['location'] + '/.gitmodules'

    depstats = []
    for dependency in config['dependencies']:
        depstats.append(__salt__['deploy.fetch'](dependency))

    # Notify the deployment system we started
    _check_in('deploy.fetch', repo)

    # Clone the repo if it doesn't exist yet
    if not __salt__['file.directory_exists'](config['location'] + '/.git'):
        cmd = '/usr/bin/git clone %s %s' % (config['url'] + '/.git',
                                            config['location'])
        status = __salt__['cmd.retcode'](cmd)
        if status != 0:
            return {'status': 5, 'repo': repo, 'dependencies': depstats}

    cmd = '/usr/bin/git remote set-url origin %s' % config['url'] + "/.git"
    __salt__['cmd.retcode'](cmd, config['location'])

    cmd = '/usr/bin/git fetch'
    status = __salt__['cmd.retcode'](cmd, config['location'])
    if status != 0:
        return {'status': 10, 'repo': repo, 'dependencies': depstats}

    cmd = '/usr/bin/git fetch --tags'
    status = __salt__['cmd.retcode'](cmd, config['location'])
    if status != 0:
        return {'status': 20, 'repo': repo, 'dependencies': depstats}

    # There's a bug with using booleans in pillars, so for now
    # we're matching against an explicit True string.
    if config['checkout_submodules'] == "True":
        cmd = '/usr/bin/git checkout .gitmodules'
        ret = __salt__['cmd.retcode'](cmd, config['location'])
        if ret != 0:
            return {'status': 30, 'repo': repo, 'dependencies': depstats}
        # Transform .gitmodules file based on defined seds
        for before, after in config['submodule_sed_regex'].items():
            after = after.replace('__REPO_URL__', config['url'])
            __salt__['file.sed'](gitmodules, before, after)

        # Sync the .gitmodules config
        cmd = '/usr/bin/git submodule sync'
        ret = __salt__['cmd.retcode'](cmd, config['location'])
        if ret != 0:
            return {'status': 40, 'repo': repo, 'dependencies': depstats}

        # fetch all submodules and tag for submodules
        cmd = '/usr/bin/git submodule foreach git fetch'
        ret = __salt__['cmd.retcode'](cmd, config['location'])
        if ret != 0:
            return {'status': 50, 'repo': repo, 'dependencies': depstats}

        # fetch all submodules and tag for submodules
        cmd = '/usr/bin/git submodule foreach git fetch --tags'
        ret = __salt__['cmd.retcode'](cmd, config['location'])
        if ret != 0:
            return {'status': 60, 'repo': repo, 'dependencies': depstats}

    cmd = '/usr/bin/git describe --always --tag origin'
    origin_tag = __salt__['cmd.run'](cmd, config['location'])
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
    config = get_config(repo)
    gitmodules = config['location'] + '/.gitmodules'
    depstats = []

    # Notify the deployment system we started
    _check_in('deploy.checkout', repo)

    # Fetch the .deploy file from the server and get the current tag
    deployfile = config['url'] + '/.deploy'
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

    for dependency in config['dependencies']:
        depstats.append(__salt__['deploy.checkout'](dependency, reset))

    if reset:
        # User requested we hard reset the repo to the tag
        cmd = '/usr/bin/git reset --hard tags/%s' % (tag)
        ret = __salt__['cmd.retcode'](cmd, config['location'])
        if ret != 0:
            return {'status': 20, 'repo': repo, 'dependencies': depstats}
    else:
        cmd = '/usr/bin/git describe --always --tag'
        current_tag = __salt__['cmd.run'](cmd, config['location'])
        current_tag = current_tag.strip()
        if current_tag == tag:
            return {'status': 0, 'repo': repo,
                    'tag': tag, 'dependencies': depstats}

    # Switch to the tag defined in the server's .deploy file
    cmd = '/usr/bin/git checkout --force --quiet tags/%s' % (tag)
    ret = __salt__['cmd.retcode'](cmd, config['location'])
    if ret != 0:
        return {'status': 30, 'repo': repo, 'dependencies': depstats}

    # There's a bug with using booleans in pillars, so for now
    # we're matching against an explicit True string.
    if config['checkout_submodules'] == "True":
        # Transform .gitmodules file based on defined seds
        for before, after in config['submodule_sed_regex'].items():
            after = after.replace('__REPO_URL__', config['url'])
            __salt__['file.sed'](gitmodules, before, after)

        # Sync the .gitmodules config
        cmd = '/usr/bin/git submodule sync'
        ret = __salt__['cmd.retcode'](cmd, config['location'])
        if ret != 0:
            return {'status': 40, 'repo': repo, 'dependencies': depstats}

        # Update the submodules to match this tag
        cmd = '/usr/bin/git submodule update --init'
        ret = __salt__['cmd.retcode'](cmd, config['location'])
        if ret != 0:
            return {'status': 50, 'repo': repo, 'dependencies': depstats}

    # Call modules on the repo's behalf ignore the return on these
    for call in config['checkout_module_calls']:
        __salt__[call](repo)
    return {'status': 0, 'repo': repo, 'tag': tag, 'dependencies': depstats}
