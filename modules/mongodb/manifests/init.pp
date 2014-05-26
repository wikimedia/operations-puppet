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
        systemLog       => {
            destination => 'file',
            logAppend   => true,
            path        => '/var/log/mongodb/mongodb.log',
        },
    }

    # HACK: since merge() does not support recursive merging,
    # we manually ensure that the required settings are in place
    if is_hash($settings[storage]) {
        $settings[storage] = merge($required_settings[storage], $settings[storage])
    } else {
        $settings[storage] = $required_settings[storage]
    }
    if is_hash($settings[systemLog]) {
        $settings[systemLog] = merge($required_settings[systemLog], $settings[systemLog])
    } else {
        $settings[systemLog] = $required_settings[systemLog]
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

    file { '/etc/mongod.conf':
        content => ordered_json($settings),
        owner   => root,
        group   => root,
        mode    => '0644',
        require => Package['mongodb-org'],
    }

    service { 'mongodb':
        ensure    => running,
        provider  => upstart,
        subscribe => File['/etc/mongod.conf'],
    }
}
