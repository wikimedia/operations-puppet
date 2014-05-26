# == Class: mongodb
#
# Provisions MongoDB, an open-source document database.
# See <http://www.mongodb.org/> for details.
#
# Requires at least Mongo 2.6. Uses mongodb-org package,
# which are provided by MongoDB themselves, rather than
# by Ubuntu.
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
        storage    => {
            dbPath => $dbpath,
        },
        systemLog     => {
            logAppend => true,
            path   => '/var/log/mongodb/mongodb.log',
        },
    }

    package { 'mongodb-org':
        ensure => present,
    }

    file { $dbpath:
        ensure  => directory,
        owner   => 'mongodb',
        group   => 'mongodb',
        mode    => '0755',
        require => Package['mongodb-org'],
    }

    file { '/etc/mongodb.conf':
        content => ordered_json(merge($required_settings, $settings)),
        owner   => root,
        group   => root,
        mode    => '0644',
        require => Package['mongodb-org'],
    }

    service { 'mongodb':
        ensure    => running,
        provider  => upstart,
        subscribe => File['/etc/mongodb.conf'],
    }
}
