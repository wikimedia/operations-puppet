# == Class: mongodb::decommission
#
# This class automates the process of retiring a MongoDB instance. It
# shuts down the MongoDB service and removes its configuration file.
# Log files and database data files (if any) are left untouched.
#
class mongodb::decommission {
    service { 'mongodb':
        ensure => stopped,
        before => Package['mongodb'],
    }

    package { 'mongodb':
        ensure  => absent,
    }

    file { '/etc/mongodb.conf':
        ensure  => absent,
    }
}
