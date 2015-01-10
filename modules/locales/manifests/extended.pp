# == Class: locales::extended
#
# Provisions a set of "extended" hand-picked locales that are useful on most
# systems. This is a tradeoff between the cost of generating all locales and
# their relative usefulness.

class locales::extended {
    include locales

    file { '/var/lib/locales/supported.d/local':
        ensure => present,
        source => 'puppet:///modules/locales/locales-extended',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        notify => Exec['locale-gen'],
    }
}
