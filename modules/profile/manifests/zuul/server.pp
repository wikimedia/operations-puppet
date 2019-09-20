class profile::zuul::server(
    $conf_common = hiera('zuul::common'),
    $conf_server = hiera('profile::zuul::server::conf'),
    $service_enable = hiera('profile::zuul::server::service_enable', true),
    $service_ensure = hiera('profile::zuul::server::service_ensure', 'running'),
    $email_server = hiera('profile::zuul::server::email_server', undef),
) {
    system::role { 'zuul::server': description => 'Zuul server (scheduler)' }

    $monitoring_active = $service_enable ? {
        false   => 'absent',
        default => 'present',
    }
    class { '::zuul::monitoring::server':
        ensure => $monitoring_active,
    }

    class { '::zuul::server':
        # Shared settings
        gerrit_server        => $conf_common['gerrit_server'],
        gerrit_user          => $conf_common['gerrit_user'],

        # Server settings
        gearman_server       => $conf_server['gearman_server'],
        gearman_server_start => $conf_server['gearman_server_start'],
        url_pattern          => $conf_server['url_pattern'],
        status_url           => $conf_server['status_url'],
        statsd_host          => $conf_server['statsd_host'],
        service_ensure       => $service_ensure,

        # Enable email configuration
        email_server         => $email_server,
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
        require   => Package['zuul'],  # for /etc/zuul
    }

}
