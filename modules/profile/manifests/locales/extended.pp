# == Class: profile::locales::extended
#
# Provisions a set of "extended" hand-picked locales that are useful on most
# systems. This is a tradeoff between the cost of generating all locales and
# their relative usefulness.

class profile::locales::extended {

    package { 'locales':
        ensure => present,
    }

    exec { 'locale-gen':
        command     => '/usr/sbin/locale-gen --purge',
        refreshonly => true,
        require     => Package['locales'],
    }

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
        source => 'puppet:///modules/profile/locales/locales-extended',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        notify => Exec['locale-gen'],
    }
}
