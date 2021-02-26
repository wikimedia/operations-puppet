class profile::zuul::server(
    Hash $conf_common = lookup('zuul::common'),
    Hash $conf_server = lookup('profile::zuul::server::conf'),
    Variant[Enum['mask', 'manual'], Boolean] $service_enable = lookup('profile::zuul::server::service_enable', {default_value => true}),
    Variant[Enum['running', 'stopped'], Boolean] $service_ensure = lookup('profile::zuul::server::service_ensure', {default_value => 'running'}),
    Stdlib::Fqdn $email_server = lookup('profile::zuul::server::email_server'),
    Array[Stdlib::Fqdn] $prometheus_nodes = lookup('prometheus_nodes'),
) {
    system::role { 'zuul::server': description => 'Zuul server (scheduler)' }

    $monitoring_active = $service_enable ? {
        false   => 'absent',
        default => 'present',
    }
    class { 'zuul::monitoring::server':
        ensure           => $monitoring_active,
        prometheus_nodes => $prometheus_nodes,
    }
    # This ensures that the mtail package is installed,
    # /etc/default/mtail exists, and systemd service is prepped.
    class { 'mtail':
      logs => ['/var/log/zuul/error.log'],
    }

    $service_enable_real = $service_enable ? {
        false   => 'mask',
        default => true,
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
        service_enable       => $service_enable_real,
        service_ensure       => $service_ensure,

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
        mode      => '0775',
        umask     => '002',
        origin    => 'https://gerrit.wikimedia.org/r/integration/config.git',
        branch    => $conf_server['config_git_branch'],
    }

}
