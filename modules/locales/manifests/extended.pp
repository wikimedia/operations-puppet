# == Class: locales::extended
#
# Provisions a set of "extended" hand-picked locales that are useful on most
# systems. This is a tradeoff between the cost of generating all locales and
# their relative usefulness.

class locales::extended {
    include ::locales

    # Ubuntu has a nice supported.d mechanism; Debian doesn't, so fall back
    # into overwriting the systems config. For Debian systems, though,
    # locales::all might be a better option, depending on the use case.
    $localeconf = $::operatingsystem ? {
        'Ubuntu' => '/var/lib/locales/supported.d/local',
        'Debian' => '/etc/locale.gen',
        default  => '/etc/locale.gen',
    }

    file { $localeconf:
        ensure => present,
        source => 'puppet:///modules/locales/locales-extended',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        notify => Exec['locale-gen'],
    }
}
