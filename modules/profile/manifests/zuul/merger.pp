# SPDX-License-Identifier: Apache-2.0
class profile::zuul::merger(
    Boolean $enable = lookup('profile::zuul::merger::enable'),
    Hash $conf_common = lookup('zuul::common'),
    Hash $conf_merger = lookup('profile::zuul::merger::conf'),
    String $ferm_srange = lookup('profile::zuul::merger::ferm_srange'),
) {
    include profile::ci

    if $enable {
        $monitoring_active = 'present'
        $service_enable    = true
    } else {
        $monitoring_active = 'absent'
        $service_enable    = 'mask'
    }

    class { 'zuul::monitoring::merger':
        ensure => $monitoring_active,
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
        service_enable      => $service_enable,
        service_ensure      => stdlib::ensure($enable, 'service'),
    }

    # Serves Zuul git repositories
    user { 'gitdaemon':
        system => true,
        gid    => 'nogroup',
        home   => '/nonexistent',  # like "nobody"
    }

    class { '::git::daemon':
        description     => 'Git daemon for Zuul merger',
        base_path       => $conf_merger['git_dir'],
        directories     => [$conf_merger['git_dir']],
        user            => 'gitdaemon',
        group           => 'nogroup',
        max_connections => 96,
        environment     => {
            'HOME' => '/var/lib/gitdaemon',
        },
        require         => User['gitdaemon'],
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
