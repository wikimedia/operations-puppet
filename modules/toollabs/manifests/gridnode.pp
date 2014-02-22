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

        file { '/var/lib/gridengine':
            ensure  => link,
            target  => "${sysdir}/gridengine",
            require => File["${sysdir}/gridengine"],
            before  => Package['gridengine-common'],
        }

    }

}

