# SPDX-License-Identifier: Apache-2.0
class profile::zuul::server(
    Hash $conf_common = lookup('zuul::common'),
    Hash $conf_server = lookup('profile::zuul::server::conf'),
    Stdlib::Fqdn $email_server = lookup('profile::zuul::server::email_server'),
) {

    include profile::ci
    if $profile::ci::manager {
        $monitoring_active = 'present'
        $service_enable = true
    } else {
        $monitoring_active = 'absent'
        $service_enable = 'mask'
    }

    class { 'zuul::monitoring::server':
        ensure => $monitoring_active,
    }
    # This ensures that the mtail package is installed,
    # /etc/default/mtail exists, and systemd service is prepped.
    class { 'mtail':
      logs => ['/var/log/zuul/error.log'],
    }

    class { '::profile::prometheus::statsd_exporter':
        enable_relay => true
    }

    profile::gerrit::sshkey { 'gerrit':
        target => '/var/lib/zuul/.ssh/known_hosts',
    }

    class { 'zuul::server':
        # Shared settings
        gerrit_server        => $conf_common['gerrit_server'],
        gerrit_user          => $conf_common['gerrit_user'],

        # Server settings
        gearman_server       => $conf_server['gearman_server'],
        gearman_server_start => $conf_server['gearman_server_start'],
        url_pattern          => $conf_server['url_pattern'],
        status_url           => $conf_server['status_url'],
        statsd_host          => $conf_server['statsd_host'],
        service_enable       => $service_enable,
        service_ensure       => stdlib::ensure($profile::ci::manager, 'service'),

        # Enable email configuration
        email_server         => $email_server,
    }

    file { '/etc/zuul':
        ensure  => 'directory',
        owner   => 'zuul',
        group   => 'zuul',
        require => User['zuul'],
    }

    # Deploy Wikimedia Zuul configuration files.
    #
    # Describe the behaviors and jobs
    # Conf file is hosted in integration/config git repo
    git::clone { 'integration/config':
        directory => '/etc/zuul/wikimedia',
        owner     => 'zuul',
        group     => 'zuul',
        origin    => 'https://gerrit.wikimedia.org/r/integration/config.git',
        branch    => $conf_server['config_git_branch'],
    }

}
