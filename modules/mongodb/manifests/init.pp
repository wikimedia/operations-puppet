# == Class: mongodb
#
# Provisions MongoDB, an open-source document database.
# See <http://www.mongodb.org/> for details.
#
# Requires at least Mongo 2.6. Uses mongodb-org package,
# which are provided by MongoDB themselves, rather than
# by Ubuntu. Package provided either via labsdebrepo or
# other means.
#
# === Parameters
#
# [*settings*]
#   A (possibly nested)hash of configuration options. For a full listing of options, see
#   <http://docs.mongodb.org/manual/reference/configuration-options/>.
#
# === Example
#
#  class { 'mongodb':
#       settings => {
#            storage    => {
#                dbPath      => "/srv/mongod"
#            },
#            systemLog       => {
#                destination => 'file',
#                logAppend   => true,
#                path        => '/var/log/mongodb/mongodb.log',
#            },
#      },
#  }
#
class mongodb (
    $settings = {},
) {
    package { 'mongodb-org':
        ensure => present,
    }

    file { $settings[storage][dbPath]:
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
