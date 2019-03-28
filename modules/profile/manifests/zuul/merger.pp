class profile::zuul::merger(
    $conf_common = hiera('zuul::common'),
    $conf_merger = hiera('profile::zuul::merger::conf'),
    $ferm_srange = hiera('profile::zuul::merger::ferm_srange'),
) {

    include ::zuul::monitoring::merger

    if os_version('debian == jessie') {
        apt::repository{ 'component-ci':
            uri        => 'http://apt.wikimedia.org/wikimedia',
            dist       => "${::lsbdistcodename}-wikimedia",
            components => 'component/ci',
            source     => false,
        }
    }

    class { '::zuul::merger':
        # Shared settings
        gerrit_server       => $conf_common['gerrit_server'],
        gerrit_user         => $conf_common['gerrit_user'],

        # Merger related
        gearman_server      => $conf_merger['gearman_server'],
        gerrit_ssh_key_file => $conf_merger['gerrit_ssh_key_file'],
        git_dir             => $conf_merger['git_dir'],
        git_email           => $conf_merger['git_email'],
        git_name            => $conf_merger['git_name'],
        zuul_url            => $conf_merger['zuul_url'],
    }

    # Serves Zuul git repositories
    class { 'contint::zuul::git_daemon':
        zuul_git_dir => $conf_merger['git_dir'],
    }

    # We run a git-daemon process to expose the zuul-merger git repositories.
    # The slaves fetch changes from it over the git:// protocol.
    # It is only meant to be used from slaves, so only accept internal
    # connections.
    ferm::service { 'git-daemon_internal':
        proto  => 'tcp',
        port   => '9418',
        srange => $ferm_srange,
    }
}
