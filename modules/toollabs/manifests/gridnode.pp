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

    file { "${sysdir}/gridengine":
        ensure  => directory,
        require => File[$sysdir],
    }

    file { '/var/lib/gridengine':
        ensure  => directory,
    }

    mount { '/var/lib/gridengine':
        ensure  => mounted,
        atboot  => False,
        device  => "${sysdir}/gridengine",
        fstype  => none,
        options => 'rw,bind',
        require => File["${sysdir}/gridengine", '/var/lib/gridengine'],
        before  => Package['gridengine-common'],
    }

}

