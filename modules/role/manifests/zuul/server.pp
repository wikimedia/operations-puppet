class role::zuul::server {
    system::role { 'role::zuul::server': description => 'Zuul server (scheduler)' }

    include contint::proxy_zuul
    include ::zuul::monitoring::server

    # Zuul server needs an API key to interact with Jenkins:
    require passwords::misc::contint::jenkins
    $jenkins_apikey = $::passwords::misc::contint::jenkins::zuul_user_apikey

    $conf = hiera_hash('zuul')
    class { '::zuul::server':
        # Shared settings
        gerrit_server        => $conf['gerrit_server'],
        gerrit_user          => $conf['gerrit_user'],
        url_pattern          => $conf['url_pattern'],
        status_url           => $conf['status_url'],

        # Server settings
        jenkins_apikey       => $jenkins_apikey,
        gearman_server       => $conf['server']['gearman_server'],
        gearman_server_start => $conf['server']['gearman_server_start'],
        jenkins_server       => $conf['server']['jenkins_server'],
        jenkins_user         => $conf['server']['jenkins_user'],
        statsd_host          => $conf['server']['statsd_host'],
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
        branch    => $conf['server']['config_git_branch'],
    }

}
