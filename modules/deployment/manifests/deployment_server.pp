# = Class: deployment::deployment_server
#
# Provision a trebuchet deployment server.
#
# == Parameters:
# - $deployer_groups: Array of unix groups to add to the trebuchet user
#
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
        require => [
            Package['salt-minion'],
            Salt::Grain['deployment_server'],
            Salt::Grain['deployment_repo_user'],
        ];
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
        notify  => Exec['deployment_server_sync_all'],
    }

    salt::grain { 'deployment_repo_user':
        grain   => 'deployment_repo_user',
        value   => 'trebuchet',
        replace => true,
    }

    exec { 'deployment_server_sync_all':
        refreshonly => true,
        path        => ['/usr/bin'],
        command     => 'salt-call saltutil.sync_all';
    }

    if $::realm != 'labs' {
      generic::systemuser { 'trebuchet':
          name   => 'trebuchet',
          shell  => '/bin/false',
          home   => '/nonexistent',
          groups => $deployer_groups,
      }
    }
}
