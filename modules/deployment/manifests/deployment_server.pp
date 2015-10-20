# = Class: deployment::deployment_server
#
# Provision a trebuchet deployment server.
#
# == Parameters:
# - $deployment_group: Default value for group ownership of any trebuchet-
#                      deployed repositories
#
class deployment::deployment_server(
    $deployment_group = undef,
) {
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
        require => Package['git'],
    }

    file { '/usr/local/bin/git-new-workdir':
        source  => 'puppet:///modules/deployment/git-new-workdir',
        mode    => '0555',
        owner   => 'root',
        group   => 'root',
        require => Package['git'],
    }

    file { '/srv/patches':
        ensure => 'directory',
        owner  => 'root',
        group  => $deployment_group,
        mode   => '0775',
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
          managehome => false,
          gid        => 'trebuchet',
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

    salt::grain { 'deployment_repo_group':
        grain   => 'deployment_repo_group',
        value   => $deployment_group,
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
        path    => ['/usr/bin', '/usr/sbin', '/sbin', '/bin'],
        command => 'salt-call deploy.deployment_server_init',
        require => [
            Package['salt-minion'],
            Salt::Grain['deployment_server'],
            Salt::Grain['deployment_repo_user'],
        ];
    }
}
