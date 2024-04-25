# = Class: deployment::deployment_server
#
# Provision a deployment server for scap3 services.
#
class deployment::deployment_server(
    $trebuchet_email = "trebuchet@${::fqdn}",
) {

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
          shell  => '/bin/false',
          home   => '/var/lib/trebuchet',
          gid    => 'trebuchet',
          system => true,
      }

      file { '/var/lib/trebuchet':
          ensure => directory,
          owner  => 'trebuchet',
          group  => 'trebuchet',
      }

      file { '/var/lib/trebuchet/.gitconfig':
        content => template('deployment/gitconfig.erb'),
        mode    => '0444',
        owner   => 'trebuchet',
        group   => 'trebuchet',
        require => File['/var/lib/trebuchet'],
      }
    }
}
