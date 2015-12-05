class role::zuul::merger {
    system::role { 'role::zuul::merger': description => 'Zuul merger' }

    include role::zuul::configuration
    include role::zuul::install
    include ::zuul::monitoring::merger

    class { '::zuul::merger':
        # Shared settings
        gearman_server => $role::zuul::configuration::shared[$::realm]['gearman_server'],
        gerrit_server  => $role::zuul::configuration::shared[$::realm]['gerrit_server'],
        gerrit_user    => $role::zuul::configuration::shared[$::realm]['gerrit_user'],
        url_pattern    => $role::zuul::configuration::shared[$::realm]['url_pattern'],
        status_url     => $role::zuul::configuration::shared[$::realm]['status_url'],

        # Merger related
        gerrit_ssh_key_file => $role::zuul::configuration::merger[$::realm]['gerrit_ssh_key_file'],
        git_dir             => $role::zuul::configuration::merger[$::realm]['git_dir'],
        git_email           => $role::zuul::configuration::merger[$::realm]['git_email'],
        git_name            => $role::zuul::configuration::merger[$::realm]['git_name'],
        zuul_url            => $role::zuul::configuration::merger[$::realm]['zuul_url'],
    }

    # Serves Zuul git repositories
    class { 'contint::zuul::git-daemon':
        zuul_git_dir => $role::zuul::configuration::merger[$::realm]['git_dir'],
    }

    # We run a git-daemon process to exposes the zuul-merger git repositories.
    # The slaves fetch changes from it over the git:// protocol.
    # It is only meant to be used from slaves, so only accept internal
    # connections.
    ferm::rule { 'git-daemon_internal':
        rule => 'proto tcp dport 9418 { saddr $INTERNAL ACCEPT; }'
    }

}
