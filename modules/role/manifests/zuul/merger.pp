class role::zuul::merger {
    system::role { 'role::zuul::merger': description => 'Zuul merger' }

    include ::zuul::monitoring::merger

    $conf = hiera_hash('zuul')
    class { '::zuul::merger':
        # Shared settings
        gerrit_server       => $conf['gerrit_server'],
        gerrit_user         => $conf['gerrit_user'],
        url_pattern         => $conf['url_pattern'],
        status_url          => $conf['status_url'],

        # Merger related
        gearman_server      => $conf['merger']['gearman_server'],
        gerrit_ssh_key_file => $conf['merger']['gerrit_ssh_key_file'],
        git_dir             => $conf['merger']['git_dir'],
        git_email           => $conf['merger']['git_email'],
        git_name            => $conf['merger']['git_name'],
        zuul_url            => $conf['merger']['zuul_url'],
    }

    # Serves Zuul git repositories
    class { 'contint::zuul::git_daemon':
        zuul_git_dir => $conf['merger']['git_dir'],
    }

    # We run a git-daemon process to exposes the zuul-merger git repositories.
    # The slaves fetch changes from it over the git:// protocol.
    # It is only meant to be used from slaves, so only accept internal
    # connections.
    ferm::rule { 'git-daemon_internal':
        rule => 'proto tcp dport 9418 { saddr $INTERNAL ACCEPT; }'
    }

}
