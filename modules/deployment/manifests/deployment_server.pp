class deployment::deployment_server($deployer_groups=[]) {
    if ! defined(Package['git-core']){
        package { 'git-core':
            ensure => present;
        }
    }
    if ! defined(Package['python-redis']){
        package { 'python-redis':
            ensure => present;
        }
    }
    if ! defined(Package['python-git']){
        package { 'python-git':
            ensure => present;
        }
    }
    package { 'trebuchet-trigger':
        ensure => present;
    }

    # Remove when added to trigger
    file { '/usr/local/bin/deploy-info':
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        source  => 'puppet:///deployment/git-deploy/utils/deploy-info',
        require => [Package['python-redis']],
    }

    # Remove when added to trigger
    file { '/usr/local/bin/service-restart':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///deployment/git-deploy/utils/service-restart',
    }

    # Remove when added to trigger
    file { '/usr/local/bin/submodule-update-server-info':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///deployment/git-deploy/utils/submodule-update-server-info',
    }

    salt::grain { 'deployment_server':
        grain   => 'deployment_server',
        value   => true,
        replace => true,
    }

    salt::grain { 'deployment_repo_user':
        grain   => 'deployment_repo_user',
        value   => 'trebuchet',
        replace => true,
    }

    generic::systemuser { 'trebuchet':
        name   => 'trebuchet',
        shell  => '/bin/false',
        home   => '/nonexistent',
        groups => $deployer_groups,
    }
}
