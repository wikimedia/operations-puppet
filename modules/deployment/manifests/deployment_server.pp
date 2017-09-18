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
}
