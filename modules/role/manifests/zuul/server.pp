class role::zuul::server {
    system::role { 'role::zuul::server': description => 'Zuul server (scheduler)' }

    include contint::proxy_zuul
    include role::zuul::configuration
    include role::zuul::install
    include ::zuul::monitoring::server

    # Zuul server needs an API key to interact with Jenkins:
    require passwords::misc::contint::jenkins
    $jenkins_apikey = $::passwords::misc::contint::jenkins::zuul_user_apikey

    class { '::zuul::server':
        # Shared settings
        gearman_server       => $role::zuul::configuration::shared[$::realm]['gearman_server'],
        gerrit_server        => $role::zuul::configuration::shared[$::realm]['gerrit_server'],
        gerrit_user          => $role::zuul::configuration::shared[$::realm]['gerrit_user'],
        url_pattern          => $role::zuul::configuration::shared[$::realm]['url_pattern'],
        status_url           => $role::zuul::configuration::shared[$::realm]['status_url'],

        # Server settings
        gearman_server_start => $role::zuul::configuration::server[$::realm]['gearman_server_start'],
        jenkins_apikey       => $jenkins_apikey,
        jenkins_server       => $role::zuul::configuration::server[$::realm]['jenkins_server'],
        jenkins_user         => $role::zuul::configuration::server[$::realm]['jenkins_user'],
        statsd_host          => $role::zuul::configuration::server[$::realm]['statsd_host'],
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
        branch    => $role::zuul::configuration::server[$::realm]['config_git_branch'],
    }

} # /role::zuul::server

