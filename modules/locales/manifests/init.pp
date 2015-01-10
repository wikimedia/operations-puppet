# == Class: locales
#
# Provisions locale data used by the C library for localization (l10n) and
# internationalization (i18n) support.

class locales {
    package { 'locales':
        ensure => present,
    }

    exec { 'locale-gen':
        command     => '/usr/sbin/locale-gen',
        refreshonly => true,
        require     => Package['locales'],
    }
}
