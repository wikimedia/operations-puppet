'''
Run git deployment commands
'''

import redis
import time
import re
import urllib
import os
import json
import pwd
import salt


def _get_redis_serv():
    '''
    Return a redis server object

    :rtype: A Redis object
    '''
    deployment_config = __pillar__.get('deployment_config')
    deploy_redis = deployment_config['redis']
    socket_connect_timeout = deploy_redis.get('socket_connect_timeout')
    if socket_connect_timeout is not None:
        socket_connect_timeout = int(socket_connect_timeout)
    serv = redis.Redis(host=deploy_redis['host'],
                       port=int(deploy_redis['port']),
                       db=int(deploy_redis['db']),
                       socket_timeout=socket_connect_timeout)
    return serv


def _check_in(function, repo):
    """
    Private function used for reporting that a function has started.
    Writes to redis with basic status information.

    :param function: The function being reported on.
    :type function: str
    :param repo: The repository being acted on.
    :type repo: str
    :rtype: None
    """
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
    """
    Maps a set of arguments to a predefined set of values. Currently only
    __REPO__ is support and will be replaced with the repository name.

    :param repo: The repo name used for mapping.
    :type repo: str
    :param args: An array of arguments to map.
    :type args: list
    :rtype: list
    """
    arg_map = {'__REPO__': repo}
    mapped_args = []
    for arg in args:
        mapped_args.append(arg_map.get(arg, arg))
    return mapped_args


def get_config(repo):
    """
    Fetches the configuration for this repo from the pillars and returns
    a hash with the munged configuration (with defaults and helper config).

    :param repo: The specific repo for which to return config data.
    :type repo: str
    :rtype: hash
    """
    deployment_config = __pillar__.get('deployment_config')
    config = __pillar__.get('repo_config')
    config = config[repo]
    config.setdefault('type', 'git-http')
    # location is the location on the filesystem of the repository
    # shadow_location is the location on the filesystem of the shadow
    # reference repository.
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
    # TODO: fetch scheme/url from implementation
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
    # The url of the remote on the deployment server. Target hosts will fetch
    # from this during deployment.
    config['url'] = '{0}://{1}/{2}'.format(scheme, server, repo)
    # checkout_submodules determines whether or not this repo should
    # recursively fetch and checkout submodules.
    config.setdefault('checkout_submodules', False)
    # If gitfat_enabled is true, git-fat will be initialized and
    # git-fat pull will be run on each target as part of the checkout.
    config.setdefault('gitfat_enabled', False)
    # dependencies are a set of repositories that should be fetched
    # and checked out before this repo. This is a deprecated feature.
    config.setdefault('dependencies', {})
    # fetch_module_calls is a hash of salt modules with a list of arguments
    # that will be called at the end of the fetch stage.
    # TODO (ryan-lane): add a pre-fetch option
    config.setdefault('fetch_module_calls', {})
    # checkout_module_calls is a hash of salt modules with a list of arguments
    # that will be called at the end of the checkout stage.
    # TODO (ryan-lane): add a pre-checkout option
    config.setdefault('checkout_module_calls', {})
    # sync_script specifies the script that should be linked to on the
    # deployment server for the perl git-deploy. This option is deprecated.
    config.setdefault('sync_script', 'shared.py')
    # upstream specifies the upstream url of the repository and is used
    # to clone repositories on the deployment server.
    config.setdefault('upstream', None)
    # shadow_reference determines whether or not to make a reference clone
    # of a repository on the minions during the fetch stage. This feature
    # enables fetch_module_calls modules to run commands against the current
    # checkout of code before it's made live.
    config.setdefault('shadow_reference', False)
    # service_name is the service associated with this repository and
    # allows the deployment module to run service restart/stop/start/etc
    # for services without allowing end-users the ability to restart all
    # services on the targets.
    config.setdefault('service_name', None)
    # deployment_repo_group is the group that will own the repository
    # after deployment_server_init. This option overrides the
    # deployment_repo_group grain set for all repositories
    config.setdefault('deployment_repo_group', None)
    return config


def deployment_server_init():
    """
    Initializes a set of repositories on the deployment server. This
    function will only run on the deployment server and will initialize
    any repository defined in the pillar configuration. This function is
    safe to call at any point.

    :rtype: int
    """
    ret_status = 0
    serv = _get_redis_serv()
    is_deployment_server = __grains__.get('deployment_server')
    if not is_deployment_server:
        return ret_status
    deploy_user = __grains__.get('deployment_repo_user')
    deploy_group = __grains__.get('deployment_repo_group')
    repo_config = __pillar__.get('repo_config')
    for repo in repo_config:
        config = get_config(repo)
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
                                                 cwd=config['location'])

                # http will likely be used as deploy targets' remote transport.
                # submodules don't know how to work properly via http
                # remotes unless info/refs and other files are up to date.
                # This will call git update-server-info for each of the
                # checkouts inside of the .git/modules/<modulename> directory.
                cmd = ("""git submodule foreach --recursive """
                       """'cd $(sed "s/^gitdir: //" .git) && """
                       """git update-server-info'""")

                status = __salt__['cmd.retcode'](cmd, runas=deploy_user,
                                                 umask=002,
                                                 cwd=config['location'])

                # Install a post-checkout hook to run update-server-info
                # for each submodule.  This command needs to be run
                # every time the repository is changed.
                hook_directory = os.path.join(
                    config['location'], '.git', 'hooks'
                )
                post_checkout_path = os.path.join(
                    hook_directory, 'post-checkout'
                )
                post_checkout = open(post_checkout_path, 'w')
                post_checkout.write(cmd + "\n")
                post_checkout.close()
                os.chmod(post_checkout_path, 775)

                # we should run this on post-commit too, so just symlink
                # post-commit to post-checkout
                post_commit_path = os.path.join(hook_directory, 'post-commit')
                os.symlink(post_checkout_path, post_commit_path)
                # chown the hooks to the deploy_user
                deploy_uid = pwd.getpwnam(deploy_user).pw_uid
                os.chown(post_checkout_path, deploy_uid, -1)
                os.lchown(post_commit_path, deploy_uid, -1)
            else:
                cmd = '/usr/bin/git init %s' % (config['location'])
                status = __salt__['cmd.retcode'](cmd, runas=deploy_user,
                                                 umask=002)
            if status != 0:
                ret_status = 1
                continue
            # git clone does ignore umask and does explicit mkdir with 755
            __salt__['file.set_mode'](config['location'], 2775)

        # Set the repo name in the repo's config
        cmd = 'git config deploy.repo-name %s' % repo
        status = __salt__['cmd.retcode'](cmd, cwd=config['location'],
                                         runas=deploy_user, umask=002)
        if status != 0:
            ret_status = 1
            continue
        # Ensure checkout-submodules is also configured for trigger
        if config['checkout_submodules']:
            cmd = 'git config deploy.checkout-submodules true'
        else:
            cmd = 'git config deploy.checkout-submodules false'
        status = __salt__['cmd.retcode'](cmd, cwd=config['location'],
                                         runas=deploy_user, umask=002)
        if status != 0:
            ret_status = 1
            continue

        # Override deploy_group with repo specific value set
        # in deployment_config pillar
        if config['deployment_repo_group']:
            deploy_group = config['deployment_repo_group']

        if deploy_group is not None:
            cmd = 'chown -R %s:%s %s' % (deploy_user,
                                         deploy_group,
                                         config['location'])
            status = __salt__['cmd.retcode'](cmd,
                                             cwd=config['location'])
            if status != 0:
                ret_status = 1
    return ret_status


def sync_all():
    '''
    Sync all repositories for this minion. If a repo doesn't exist on target,
    clone it as well. This function will ensure all repositories for the
    minion are at the current tag as defined by the master and is
    be safe to call at any point.

    CLI Example (from the master):

        salt -G 'deployment_target:test' deploy.sync_all

    CLI Example (from a minion):

        salt-call deploy.sync_all

    :rtype: hash
    '''
    repo_config = __pillar__.get('repo_config')
    deployment_target = __grains__.get('deployment_target')
    status = 0
    stats = {}

    for repo in repo_config:
        # Ensure the minion is a deployment target for this repo
        if repo not in deployment_target:
            continue
        if repo not in stats:
            stats[repo] = {}
        stats[repo]["deploy.fetch"] = __salt__['deploy.fetch'](repo)
        stats[repo]["deploy.checkout"] = __salt__['deploy.checkout'](repo)

    return {'status': status, 'stats': stats}


def _update_gitmodules(config, location, shadow=False):
    """
    Finds all .gitmodules in a repository, changes all submodules within them
    to point to the correct submodule on the deployment server, then runs
    a submodule sync. This function is in support of recursive submodules.

    In the case we need to update a shadow reference repo, the .gitmodules
    files will have their submodules point to the reference clone.

    :param config: The config hash for the repo (as pulled from get_config).
    :type config: hash
    :param location: The location on the filesystem to find the .gitmodules
                     files.
    :type location: str
    :param shadow: Defines whether or not this is a shadow reference repo.
    :type shadow: bool
    :rtype: int
    """
    gitmodules_list = __salt__['file.find'](location, name='.gitmodules')
    for gitmodules in gitmodules_list:
        gitmodules_dir = os.path.dirname(gitmodules)
        # Check to see if this is even a repo with submodules. Some repos
        # have git repositories checked into the repository and kept the
        # git configuration files when doing so. This will cause our submodule
        # calls to fail.
        cmd = '/usr/bin/git submodule status --quiet'
        status = __salt__['cmd.retcode'](cmd, gitmodules_dir)
        if status != 0:
            continue
        # Ensure we're working with an unmodified .gitmodules file
        cmd = '/usr/bin/git checkout .gitmodules'
        status = __salt__['cmd.retcode'](cmd, gitmodules_dir)
        if status != 0:
            return status
        # Get a list of the submodules
        submodules = []
        f = open(gitmodules, 'r')
        for line in f.readlines():
            keyval = line.split(' = ')
            if keyval[0].strip() == "path":
                submodules.append(keyval[1].strip())
        f.close()
        if shadow:
            # Transform .gitmodules based on reference. Point the submodules
            # to the local git repository this repo references.
            reference_dir = gitmodules_dir.replace(location,
                                                   config['location'])
            f = open(gitmodules, 'w')
            for submodule in submodules:
                f.write('[submodule "{0}"]\n'.format(submodule))
                f.write('\tpath = {0}\n'.format(submodule))
                f.write('\turl = {0}/{1}\n'.format(reference_dir, submodule))
            f.close()
        else:
            # Transform .gitmodules file based on url. Point the submodules
            # to the appropriate place on the deployment server. We can base
            # this on a subpath of the repository since the deployment server
            # isn't a bare clone.
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
        # Have git update its submodule configuration from the .gitmodules
        # file.
        cmd = '/usr/bin/git submodule sync'
        status = __salt__['cmd.retcode'](cmd, gitmodules_dir)
        if status != 0:
            return status
    return 0


def _gitfat_installed():
    return salt.utils.which('git-fat')


def _init_gitfat(location):
    '''
    Runs git fat init at this location.

    :param location: The location on the filesystem to run git fat init
    :type location: str
    '''
    # if it isn't then initialize it now
    cmd = '/usr/bin/git fat init'
    return __salt__['cmd.retcode'](cmd, location)


# TODO: git fat gc?
def _update_gitfat(location):
    '''
    Runs git-fat pull at this location.
    If git fat has not been initialized for the
    repository at this location, _init_gitfat
    will be called first.

    :param location: The location on the filesystem to run git fat pull
    :type location: str
    :rtype int
    '''

    # Make sure git fat is installed.
    if not _gitfat_installed():
        return 40

    # Make sure git fat is initialized.
    cmd = '/usr/bin/git config --get filter.fat.smudge'
    if __salt__['cmd.run'](cmd, location) != 'git-fat filter-smudge':
        status = _init_gitfat(location)
        if status != 0:
            return status

    # Run git fat pull.
    cmd = '/usr/bin/git fat pull'
    return __salt__['cmd.retcode'](cmd, location)


def _clone(config, location, tag, shadow=False):
    """
    Perform a clone of a repo at a specified location, and
    do a fetch and checkout of the repo to ensure it's at the
    current deployment tag.

    :param config: Config hash as fetched from get_config
    :type config: hash
    :param location: The location on the filesystem to clone this repo.
    :type location: str
    :param tag: The tag to ensure this clone is checked out to.
    :type tag: str
    :param shadow: Whether or not this repo is a shadow reference.
    :type shadow: bool
    :rtype: int
    """
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

    CLI Example (from the master):

        salt -G 'deployment_target:test' deploy.fetch 'test/testrepo'

    CLI Example (from the minion):

        salt-call deploy.fetch 'test/testrepo'

    :param repo: The repo on which to perform the fetch.
    :type repo: str
    :rtype: hash
    '''
    config = get_config(repo)

    # Call fetch on all repositories we depend on and add it to the stats for
    # reporting back. Deprecated.
    depstats = []
    for dependency in config['dependencies']:
        depstats.append(__salt__['deploy.fetch'](dependency))

    # Notify the deployment system we started.
    _check_in('deploy.fetch', repo)

    # We need to fetch the tag in case we need to clone and also to ensure the
    # fetch has the tag as defined in the deployment.
    tag = _get_tag(config)
    if not tag:
        return {'status': 10, 'repo': repo, 'dependencies': depstats}

    # Clone the repo if it doesn't exist yet otherwise just fetch. Note that
    # clone will also properly checkout the repo to the necessary tag, so this
    # won't put the repo into an inconsistent state.
    if not __salt__['file.directory_exists'](config['location'] + '/.git'):
        status = _clone(config, config['location'], tag)
        if status != 0:
            return {'status': status, 'repo': repo, 'dependencies': depstats}
    else:
        status = _fetch_location(config, config['location'])
        if status != 0:
            return {'status': status, 'repo': repo, 'dependencies': depstats}

    # Check to see if the deployment tag has been fetched.
    cmd = '/usr/bin/git show-ref refs/tags/{0}'.format(tag)
    status = __salt__['cmd.retcode'](cmd, cwd=config['location'])
    if status != 0:
        return {'status': status, 'repo': repo, 'dependencies': depstats}

    # Do the same steps as above for the shadow reference, but in the case of
    # a normal fetch also do a checkout so that fetch_module_calls can use
    # a full checkout.
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

    # Call a set of salt modules, but map the args beforehand.
    # TODO (ryan-lane): Currently if the module calls fail no error is
    #                   returned and this will silently continue on fail.
    #                   We should modify the config hash to allow for failure
    #                   options.
    for call, args in config['fetch_module_calls'].items():
        mapped_args = _map_args(repo, args)
        __salt__[call](*mapped_args)
    return {'status': status, 'repo': repo,
            'dependencies': depstats, 'tag': tag}


def _fetch_location(config, location, shadow=False):
    """
    Fetch a repo at a specified location. Optionally define this repo as a
    shadow repo.

    :param config: Config hash as fetched from get_config.
    :type config: hash
    :param location: The location on the filesystem to run the fetch.
    :type location: str
    :rtype: int
    """
    cmd = '/usr/bin/git fetch'
    status = __salt__['cmd.retcode'](cmd, location)
    if status != 0:
        return status
    # The deployment tags may not be linked to any branch, so it's safest
    # to fetch them explicitly.
    cmd = '/usr/bin/git fetch --tags'
    status = __salt__['cmd.retcode'](cmd, location)
    if status != 0:
        return status

    if config['checkout_submodules']:
        ret = _update_gitmodules(config, location, shadow)
        if ret != 0:
            return ret

        # fetch all submodules and tags for submodules
        cmd = '/usr/bin/git submodule foreach --recursive git fetch'
        status = __salt__['cmd.retcode'](cmd, location)
        if status != 0:
            return status
        # The deployment tags will not be linked to any branch for submodules,
        # so it's required to fetch them explicitly.
        cmd = '/usr/bin/git submodule foreach --recursive git fetch --tags'
        status = __salt__['cmd.retcode'](cmd, location)
        if status != 0:
            return status
    return 0


def _get_tag(config):
    """
    Fetch the current deploy file from the repo on the deployment server and
    return the current tag associated with it.

    :param config: Config hash as fetched from get_config.
    :type config: hash
    :rtype: str
    """
    # Fetch the .deploy file from the server and get the current tag
    deployfile = config['url'] + '/.git/deploy/deploy'
    try:
        f = urllib.urlopen(deployfile)
        deployinfo = f.read()
    except IOError:
        return None
    try:
        deployinfo = json.loads(deployinfo)
        tag = deployinfo['tag']
    except (KeyError, ValueError):
        return None
    # tags are user-input and are used in shell commands, ensure they are
    # only passing alphanumeric, dashes, or /.
    if re.search(r'[^a-zA-Z0-9_\-/]', tag):
        return None
    return tag


def checkout(repo, reset=False):
    '''
    Checkout the current deployment tag. Assumes a fetch has been run.

    CLI Example (on master):

        salt -G 'deployment_target:test' deploy.checkout 'test/testrepo'

    CLI Example (on minion):

        salt deploy.checkout 'test/testrepo'

    :param repo: The repo name to check out.
    :type repo: str
    :param reset: Whether or not to do a checkout and hard reset based
                  on if the repo is already at the defined tag on the
                  deployment server.
    :type reset: bool
    :rtype: hash
    '''
    config = get_config(repo)
    depstats = []
    status = -1

    # Notify the deployment system we started
    _check_in('deploy.checkout', repo)

    tag = _get_tag(config)
    if not tag:
        return {'status': status, 'repo': repo, 'dependencies': depstats}

    status = _checkout_location(config, config['location'], tag, reset)

    if status != 0:
        return {'status': status, 'repo': repo, 'tag': tag,
                'dependencies': depstats}

    # Call a set of salt modules, but map the args beforehand.
    # TODO (ryan-lane): Currently if the module calls fail no error is
    #                   returned and this will silently continue on fail.
    #                   We should modify the config hash to allow for failure
    #                   options.
    for call, args in config['checkout_module_calls'].items():
        mapped_args = _map_args(repo, args)
        __salt__[call](*mapped_args)
    return {'status': status, 'repo': repo, 'tag': tag,
            'dependencies': depstats}


def _checkout_location(config, location, tag, reset=False, shadow=False):
    """
    Checkout a repo at the specified location to the specified tag. If reset
    is true checkout the repo even if it is already at the tag defined on the
    deployment server. Optionally specify if this is a shadow reference repo.

    :param config: Config hash as fetched from get_config.
    :type config: hash
    :param location: The location on the filesystem to run this checkout.
    :type location: str
    :param tag: The tag to checkout this location to.
    :type tag: str
    :param reset: Whether or not to checkout this repo if it is already at the
                  tag specified by the deployment server.
    :type reset: bool
    :param shadow: Whether or not this is a shadow reference repo.
    :type shadow: bool
    :rtype: int
    """
    # Call checkout on all repositories we depend on and add it to the stats
    # for reporting back. Deprecated.
    for dependency in config['dependencies']:
        depstats.append(__salt__['deploy.checkout'](dependency, reset))

    if reset:
        # User requested we hard reset the repo to the tag
        cmd = '/usr/bin/git reset --hard tags/%s' % (tag)
        ret = __salt__['cmd.retcode'](cmd, location)
        if ret != 0:
            return 20
    else:
        # Find the current tag. If it matches the requested deployment tag
        # then no further work is needed, just return.
        cmd = '/usr/bin/git describe --always --tag'
        current_tag = __salt__['cmd.run'](cmd, location)
        current_tag = current_tag.strip()
        if current_tag == tag:
            return 0

    # Checkout to the tag requested by the deployment.
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

    # Trigger git-fat pull if gitfat_enabled
    if config['gitfat_enabled']:
        ret = _update_gitfat(location)
        if ret != 0:
            return ret

    return 0


def restart(repo):
    '''
    Restart the service associated with this repo.

    CLI Example (on the master):

        salt -G 'deployment_target:test' deploy.restart 'test/testrepo'

    CLI Example (on the minion):

        salt-call deploy.restart 'test/testrepo'

    :param repo: The repo name used to find the service to restart.
    :type repo: str
    :rtype: hash
    '''
    config = get_config(repo)
    _check_in('deploy.restart', repo)

    # Call restart on all repositories we depend on and add it to the stats
    # for reporting back. Deprecated.
    depstats = []
    for dependency in config['dependencies']:
        depstats.append(__salt__['deploy.restart'](dependency))

    # Get the service associated with this repo and have salt call a restart.
    if config['service_name']:
        status = __salt__['service.restart'](config['service_name'])
        return {'status': status, 'repo': repo, 'dependencies': depstats}
    else:
        return {}


def fixurl(git_server):
    """
    Allows to recursively fix all the remotes in git repositories on a target.
    """
    repo_config = __pillar__.get('repo_config')
    deployment_target = __grains__.get('deployment_target')
    for repo in repo_config:
        if repo not in deployment_target:
            continue
        conf = get_config(repo)
        # If it has not been checked out, there is no reason to fix the url
        if not __salt__['file.directory_exists'](conf['location']):
            continue
        cmd = '/usr/bin/git remote set-url origin {0}/.git'.format(
            conf['url'])
        retval =  __salt__['cmd.retcode'](cmd, cwd=repo_config['location'])
        if retval != 0:
            return retval
    return 0
