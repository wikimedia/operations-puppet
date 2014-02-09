'''
Run git deployment commands
'''

import redis
import time
import re
import urllib
import os


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
    minion_key = 'deploy:{0}:minions:{1}'.format(repo, minion)
    if function == "deploy.fetch":
        serv.hset(minion_key, 'fetch_checkin_timestamp', timestamp)
    elif function == "deploy.checkout":
        serv.hset(minion_key, 'checkout_checkin_timestamp', timestamp)
    elif function == "deploy.restart":
        serv.hset(minion_key, 'restart_checkin_timestamp', timestamp)


def _map_args(repo, args):
    arg_map = {'__REPO__': repo}
    mapped_args = []
    for arg in args:
        mapped_args.append(arg_map.get(arg, arg))
    return mapped_args


def get_config(repo):
    deployment_config = __pillar__.get('deployment_config')
    config = __pillar__.get('repo_config')
    config = config[repo]
    config.setdefault('type', 'git-http')
    if 'location' in config:
        location = config['location']
        shadow_location = '{0}/.{1}'.format(os.path.dirname(location),
                                            os.path.basename(location))
        config['shadow_location'] = shadow_location
    else:
        location = '{0}/{1}'.format(deployment_config['parent_dir'], repo)
        config['location'] = location
        shadow_repo = '{0}/.{1}'.format(os.path.dirname(repo),
                                        os.path.basename(repo))
        shadow_location = '{0}/{1}'.format(deployment_config['parent_dir'],
                                           shadow_repo)
        config['shadow_location'] = shadow_location
    site = __grains__.get('site')
    server = deployment_config['servers'][site]
    #TODO: fetch scheme/url from implementation
    if config['type'] == 'git-http':
        scheme = 'http'
    elif config['type'] == 'git-https':
        scheme = 'https'
    elif config['type'] == 'git-ssh':
        scheme = 'ssh'
    elif config['type'] == 'git':
        scheme = 'git'
    else:
        scheme = 'http'
    config['url'] = '{0}://{1}/{2}'.format(scheme, server, repo)
    config.setdefault('checkout_submodules', False)
    config.setdefault('dependencies', {})
    config.setdefault('checkout_module_calls', {})
    config.setdefault('fetch_module_calls', {})
    config.setdefault('sync_script', 'shared.py')
    config.setdefault('upstream', None)
    config.setdefault('shadow_reference', False)
    config.setdefault('service_name', None)
    return config


def deployment_server_init():
    serv = _get_redis_serv()
    is_deployment_server = __grains__.get('deployment_server')
    hook_dir = __grains__.get('deployment_global_hook_dir')
    if not is_deployment_server:
        return 0
    deploy_user = __grains__.get('deployment_repo_user')
    repo_config = __pillar__.get('repo_config')
    for repo in repo_config:
        config = get_config(repo)
        repo_sync_dir = '{0}/sync/{1}'.format(hook_dir, os.path.dirname(repo))
        sync_link = '{0}/{1}.sync'.format(repo_sync_dir,
                                          os.path.basename(repo))
        # Create repo sync dir
        if not __salt__['file.directory_exists'](repo_sync_dir):
            __salt__['file.mkdir'](repo_sync_dir)
        # Create repo sync script link
        if not __salt__['file.file_exists'](sync_link):
            sync_script = '{0}/sync/{1}'.format(hook_dir,
                                                config['sync_script'])
            __salt__['file.symlink'](sync_script, sync_link)
        # Clone repo from upstream or init repo with no upstream
        if not __salt__['file.directory_exists'](config['location'] + '/.git'):
            if config['upstream']:
                cmd = '/usr/bin/git clone %s/.git %s' % (config['upstream'],
                                                         config['location'])
                status = __salt__['cmd.retcode'](cmd, runas=deploy_user,
                                                 umask=002)
                if status != 0:
                    ret_status = 1
                    continue
                # We don't check the checkout_submodules config flag here
                # on purpose. The deployment server should always have a
                # fully recursive clone and minions should decide whether
                # or not they'll use the submodules. This avoids consistency
                # issues in the case where submodules are later enabled, but
                # someone forgets to check them out.
                cmd = '/usr/bin/git submodule update --init --recursive'
                status = __salt__['cmd.retcode'](cmd, runas=deploy_user,
                                                 umask=002,
                                                 config['location'])
            else:
                cmd = '/usr/bin/git init %s' % (config['location'])
                status = __salt__['cmd.retcode'](cmd, runas=deploy_user,
                                                 umask=002)
            if status != 0:
                return status
            # git clone does ignores umask and does explicit mkdir with 755
            __salt__['file.set_mode'](config['location'], 2775)
            # Set the repo name in the repo's config
            cmd = 'git config deploy.tag-prefix %s' % repo
            status = __salt__['cmd.retcode'](cmd, cwd=config['location'],
                                             runas=deploy_user, umask=002)
            if status != 0:
                return status
    return 0


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


def _update_gitmodules(config, location, shadow=False):
    gitmodules_list = __salt__['file.find'](location, name='.gitmodules')
    for gitmodules in gitmodules_list:
        gitmodules_dir = os.path.dirname(gitmodules)
        cmd = '/usr/bin/git checkout .gitmodules'
        status = __salt__['cmd.retcode'](cmd, gitmodules_dir)
        if status != 0:
            return status
        submodules = []
        f = open(gitmodules, 'r')
        for line in f.readlines():
            keyval = line.split(' = ')
            if keyval[0].strip() == "path":
                submodules.append(keyval[1].strip())
        f.close()
        if shadow:
            # Tranform .gitmodules based on reference
            reference_dir = gitmodules_dir.replace(location,
                                                   config['location'])
            f = open(gitmodules, 'w')
            for submodule in submodules:
                f.write('[submodule "{0}"]\n'.format(submodule))
                f.write('\tpath = {0}\n'.format(submodule))
                f.write('\turl = {0}/{1}\n'.format(reference_dir, submodule))
            f.close()
        else:
            # Transform .gitmodules file based on url
            cmd = '/usr/bin/git config remote.origin.url'
            remote = __salt__['cmd.run'](cmd, gitmodules_dir)
            if not remote:
                return 1
            f = open(gitmodules, 'w')
            for submodule in submodules:
                submodule_path = 'modules/{0}'.format(submodule)
                f.write('[submodule "{0}"]\n'.format(submodule))
                f.write('\tpath = {0}\n'.format(submodule))
                f.write('\turl = {0}/{1}\n'.format(remote, submodule_path))
            f.close()
        # Sync submodules for this repo
        cmd = '/usr/bin/git submodule sync'
        status = __salt__['cmd.retcode'](cmd, gitmodules_dir)
        if status != 0:
            return status
    return 0


def _clone(config, location, tag, shadow=False):
    if shadow:
        cmd = '/usr/bin/git clone --reference {0} {1}/.git {2}'
        cmd = cmd.format(config['location'], config['url'], location)
    else:
        cmd = '/usr/bin/git clone {0}/.git {1}'.format(config['url'], location)
    status = __salt__['cmd.retcode'](cmd)
    if status != 0:
        return status
    status = _fetch_location(config, location, shadow=shadow)
    if status != 0:
        return status
    status = _checkout_location(config, location, tag,
                                reset=True, shadow=shadow)
    if status != 0:
        return status
    return 0


def fetch(repo):
    '''
    Call a fetch for the specified repo

    CLI Example::

        salt -G 'cluster:appservers' deploy.fetch 'slot0'
    '''
    config = get_config(repo)

    depstats = []
    for dependency in config['dependencies']:
        depstats.append(__salt__['deploy.fetch'](dependency))

    # Notify the deployment system we started
    _check_in('deploy.fetch', repo)

    tag = _get_tag(config)
    if not tag:
        return {'status': 10, 'repo': repo, 'dependencies': depstats}

    # Clone the repo if it doesn't exist yet
    if not __salt__['file.directory_exists'](config['location'] + '/.git'):
        status = _clone(config, config['location'], tag)
        if status != 0:
            return {'status': status, 'repo': repo, 'dependencies': depstats}
    else:
        status = _fetch_location(config, config['location'])
        if status != 0:
            return {'status': status, 'repo': repo, 'dependencies': depstats}

    cmd = '/usr/bin/git show-ref refs/tags/{0}'.format(tag)
    status = __salt__['cmd.retcode'](cmd, cwd=config['location'])
    if status != 0:
        return {'status': status, 'repo': repo, 'dependencies': depstats}

    if config['shadow_reference']:
        shadow_gitdir = config['shadow_location'] + '/.git'
        if not __salt__['file.directory_exists'](shadow_gitdir):
            status = _clone(config, config['shadow_location'], tag,
                            shadow=True)
            if status != 0:
                return {'status': status, 'repo': repo,
                        'dependencies': depstats}
        else:
            status = _fetch_location(config, config['shadow_location'],
                                     shadow=True)
            if status != 0:
                return {'status': status, 'repo': repo,
                        'dependencies': depstats}
            status = _checkout_location(config, config['shadow_location'], tag,
                                        reset=False, shadow=True)
            if status != 0:
                return {'status': status, 'repo': repo,
                        'dependencies': depstats}

    # Call modules on the repo's behalf ignore the return on these
    for call, args in config['fetch_module_calls'].items():
        mapped_args = _map_args(repo, args)
        __salt__[call](*mapped_args)
    return {'status': status, 'repo': repo,
            'dependencies': depstats, 'tag': tag}


def _fetch_location(config, location, shadow=False):
    cmd = '/usr/bin/git fetch --all'
    status = __salt__['cmd.retcode'](cmd, location)
    if status != 0:
        return status

    # TODO: update .gitmodules recursively, then run submodule commands
    #       recursively.
    if config['checkout_submodules']:
        ret = _update_gitmodules(config, location, shadow)
        if ret != 0:
            return ret

        # fetch all submodules and tag for submodules
        cmd = '/usr/bin/git submodule foreach --recursive git fetch --all'
        status = __salt__['cmd.retcode'](cmd, location)
        if status != 0:
            return status
    return 0


def _get_tag(config):
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
        return None
    # tags are user-input and are used in shell commands, ensure they are
    # only passing alphanumeric.
    if re.match('\W+', tag):
        return None
    return tag


def checkout(repo, reset=False):
    '''
    Checkout the current deployment tag. Assumes a fetch has been run.

    CLI Example::

        salt -G 'cluster:appservers' deploy.checkout 'slot0'
    '''
    #TODO: replace the cmd.retcode calls with git module calls,
    # where appropriate
    config = get_config(repo)
    depstats = []

    # Notify the deployment system we started
    _check_in('deploy.checkout', repo)

    tag = _get_tag(config)
    if not tag:
        return {'status': status, 'repo': repo, 'dependencies': depstats}

    status = _checkout_location(config, config['location'], tag, reset)

    if status != 0:
        return {'status': status, 'repo': repo, 'tag': tag,
                'dependencies': depstats}

    # Call modules on the repo's behalf ignore the return on these
    for call, args in config['checkout_module_calls'].items():
        mapped_args = _map_args(repo, args)
        __salt__[call](*mapped_args)
    return {'status': status, 'repo': repo, 'tag': tag,
            'dependencies': depstats}


def _checkout_location(config, location, tag, reset=False, shadow=False):
    for dependency in config['dependencies']:
        depstats.append(__salt__['deploy.checkout'](dependency, reset))

    if reset:
        # User requested we hard reset the repo to the tag
        cmd = '/usr/bin/git reset --hard tags/%s' % (tag)
        ret = __salt__['cmd.retcode'](cmd, location)
        if ret != 0:
            return 20
    else:
        cmd = '/usr/bin/git describe --always --tag'
        current_tag = __salt__['cmd.run'](cmd, location)
        current_tag = current_tag.strip()
        if current_tag == tag:
            return 0

    # Switch to the tag defined in the server's .deploy file
    cmd = '/usr/bin/git checkout --force --quiet tags/%s' % (tag)
    ret = __salt__['cmd.retcode'](cmd, location)
    if ret != 0:
        return 30

    if config['checkout_submodules']:
        ret = _update_gitmodules(config, location, shadow)
        if ret != 0:
            return ret

        # Update the submodules to match this tag
        cmd = '/usr/bin/git submodule update --recursive --init'
        ret = __salt__['cmd.retcode'](cmd, location)
        if ret != 0:
            return 50
    return 0


def restart(repo):
    '''
    Restart the service associated with this repo.

    CLI Example::

        salt -G 'cluster:appservers' deploy.restart 'slot0'
    '''
    config = get_config(repo)
    _check_in('deploy.restart', repo)

    depstats = []
    for dependency in config['dependencies']:
        depstats.append(__salt__['deploy.restart'](dependency))

    if config['service_name']:
        status = __salt__['service.restart'](config['service_name'])
        return {'status': status, 'repo': repo, 'dependencies': depstats}
    else:
        return {}
