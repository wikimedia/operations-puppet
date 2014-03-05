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

    exec { 'eventual_consistency_deployment_server_init':
        path    => ['/usr/bin'],
        command => 'salt-call deploy.deployment_server_init',
        require => Package['salt-minion'];
    }

    file { '/etc/gitconfig':
        content => template('deployment/gitconfig.erb'),
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        require => [Package['git-core']],
    }
    if ! defined(Package['python-git']){
        package { 'python-git':
            ensure => present;
        }
    }
    package { 'python-gitdb':
        ensure => present;
    }
    package { 'trebuchet-trigger':
        ensure => present;
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
