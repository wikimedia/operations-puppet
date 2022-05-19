# = Class: deployment::deployment_server
#
# Provision a deployment server for scap3 services.
#
class deployment::deployment_server() {
    include ::redis::client::python

    ensure_packages([
        'python-gitdb',
        'python-git',
        ])

    file { '/usr/local/bin/git-new-workdir':
        source  => 'puppet:///modules/deployment/git-new-workdir',
        mode    => '0555',
        owner   => 'root',
        group   => 'root',
        require => Package['git'],
    }

    file { '/srv/deployment':
        ensure => directory,
        owner  => 'trebuchet',
        group  => 'wikidev',
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
