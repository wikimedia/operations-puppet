# filtertags: labs-project-ci-staging
class role::zuul::server {
    system::role { 'role::zuul::server': description => 'Zuul server (scheduler)' }

    include contint::proxy_zuul

    $monitoring_active = hiera('zuul::server::service_enable') ? {
        false   => 'absent',
        default => 'present',
    }
    class { '::zuul::monitoring::server':
        ensure => $monitoring_active,
    }

    $conf_common = hiera('zuul::common')
    $conf_server = hiera('zuul::server')
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
        origin    => 'https://gerrit.wikimedia.org/r/p/integration/config.git',
        branch    => $conf_server['config_git_branch'],
    }

}
