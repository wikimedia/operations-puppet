class role::zuul::merger {
    system::role { 'role::zuul::merger': description => 'Zuul merger' }

    include ::zuul::monitoring::merger

    $conf_common = hiera_hash('zuul::common')
    class { '::zuul::merger':
        # Shared settings
        gerrit_server => $conf_common['gerrit_server'],
        gerrit_user   => $conf_common['gerrit_user'],
        url_pattern   => $conf_common['url_pattern'],
        status_url    => $conf_common['status_url'],
    }

    # Serves Zuul git repositories
    class { 'contint::zuul::git_daemon':
        zuul_git_dir => $zuul::merger::git_dir,
    }

    # We run a git-daemon process to exposes the zuul-merger git repositories.
    # The slaves fetch changes from it over the git:// protocol.
    # It is only meant to be used from slaves, so only accept internal
    # connections.
    ferm::service { 'git-daemon_internal':
        proto  => 'tcp',
        port   => '9418',
        srange => '(($LABS_NETWORKS @resolve(gallium.wikimedia.org) @resolve(contint1001.wikimedia.org) ))',
    }
}
