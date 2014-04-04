# Class: toollabs::execnode
#
# This class applies to all grid-related node roles
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class toollabs::gridnode inherits toollabs {

    file { "${toollabs::sysdir}/gridengine":
        ensure  => directory,
        require => File[$toollabs::sysdir],
    }

    file { '/var/lib/gridengine':
        ensure  => directory,
    }

    mount { '/var/lib/gridengine':
        ensure  => mounted,
        atboot  => False,
        device  => "${toollabs::sysdir}/gridengine",
        fstype  => none,
        options => 'rw,bind',
        require => File["${toollabs::sysdir}/gridengine",
                        '/var/lib/gridengine'],
        before  => Package['gridengine-common'],
    }

}
