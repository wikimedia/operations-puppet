# == Class: mongodb
#
# Provisions MongoDB, an open-source document database.
# See <http://www.mongodb.org/> for details.
#
# === Parameters
#
# [*dbpath*]
#   Set this value to designate a directory for the mongod instance to
#   store its data. Defaults to '/srv/mongod'.
#
# [*settings*]
#   A hash of configuration options. For a full listing of options, see
#   <http://docs.mongodb.org/manual/reference/configuration-options/>.
#
# === Example
#
#  class { 'mongodb':
#      settings => {
#          auth => true,
#          port => 29001,
#      },
#  }
#
class mongodb (
    $dbpath   = '/srv/mongod',
    $settings = {},
) {
    # Base settings required by this Puppet module.
    $required_settings = {
        dbpath      => $dbpath,
        fork        => false,
        logappend   => true,
        logpath     => '/var/log/mongodb/mongodb.log',
    }

    package { 'mongodb':
        ensure => present,
    }

    file { $dbpath:
        ensure  => directory,
        owner   => 'mongodb',
        group   => 'mongodb',
        mode    => '0755',
        require => Package['mongodb'],
    }

    file { '/etc/mongodb.conf':
        content => template('mongodb/mongod.conf.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => Package['mongodb'],
    }

    service { 'mongodb':
        ensure    => running,
        subscribe => File['/etc/mongodb.conf'],
    }

    base::service_auto_restart { 'mongodb': }
}
