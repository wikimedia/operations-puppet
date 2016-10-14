class role::zuul::server {
    system::role { 'role::zuul::server': description => 'Zuul server (scheduler)' }

    include contint::proxy_zuul
    include ::zuul::monitoring::server

    # Zuul server needs an API key to interact with Jenkins:
    require passwords::misc::contint::jenkins
    $jenkins_apikey = $::passwords::misc::contint::jenkins::zuul_user_apikey

    $conf_common = hiera('zuul::common')
    $conf_server = hiera('zuul::server')
    class { '::zuul::server':
        # Shared settings
        gerrit_server        => $conf_common['gerrit_server'],
        gerrit_user          => $conf_common['gerrit_user'],
        url_pattern          => $conf_common['url_pattern'],
        status_url           => $conf_common['status_url'],

        # Server settings
        jenkins_apikey       => $jenkins_apikey,
        gearman_server       => $conf_server['gearman_server'],
        gearman_server_start => $conf_server['gearman_server_start'],
        jenkins_server       => $conf_server['jenkins_server'],
        jenkins_user         => $conf_server['jenkins_user'],
        statsd_host          => $conf_server['statsd_host'],
    }

    # Deploy Wikimedia Zuul configuration files.
    #
    # Describe the behaviors and jobs
    # Conf file is hosted in integration/config git repo
    git::clone { 'integration/config':
        directory => '/etc/zuul/wikimedia',
        owner     => zuul,
        group     => zuul,
        mode      => '0775',
        umask     => '002',
        origin    => 'https://gerrit.wikimedia.org/r/p/integration/config.git',
        branch    => $conf_server['config_git_branch'],
    }

}
