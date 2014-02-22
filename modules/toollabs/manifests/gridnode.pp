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

    if $::site == 'eqiad' {

        file { "${sysdir}/gridengine":
            ensure  => directory,
            require => File[$sysdir],
        }

        mount { '/var/lib/gridengine':
            ensure  => mounted,
            atboot  => False,
            device  => "${sysdir}/gridengine",
            fstype  => none,
            options => 'rw.bind',
            require => File["${sysdir}/gridengine"],
            before  => Package['gridengine-common'],
        }

    }

}

