# = Class: deployment::deployment_server
#
# Provision a trebuchet deployment server.
#
# == Parameters:
# - $deployer_groups: Array of unix groups to add to the trebuchet user
#
class deployment::deployment_server($deployer_groups=[]) {
    include ::redis::client::python

    ensure_packages([
        'python-gitdb',
        'python-git',
        ])

    package { 'trebuchet-trigger':
        ensure => present;
    }

    file { '/etc/gitconfig':
        content => template('deployment/gitconfig.erb'),
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        require => [Package['git-core']],
    }

    file { '/srv/patches':
      ensure   => 'directory',
      owner    => 'root',
      group    => $deployer_groups[0],
      mode     => '0775',
    }

    if $::realm != 'labs' {

      group { 'trebuchet':
          ensure => present,
          name   => 'trebuchet',
          system => true,
      }

      user { 'trebuchet':
          shell      => '/bin/false',
          home       => '/nonexistent',
          managehome => true,
          gid        => 'trebuchet',
          groups     => $deployer_groups,
          system     => true,
      }
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

    exec { 'deployment_server_sync_all':
        refreshonly => true,
        path        => ['/usr/bin'],
        command     => 'salt-call saltutil.sync_all',
        subscribe   => Salt::Grain['deployment_server'],
        timeout     => 1200,
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
}
