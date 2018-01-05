# == Class: profile::locales::all
#
# Provisions all available supported locales. WARNING: this can take a very
# long time on Ubuntu systems; consider using profile::locales::extended.

class profile::locales::all {

    package { 'locales':
        ensure => present,
    }

    exec { 'locale-gen':
        command     => '/usr/sbin/locale-gen --purge',
        refreshonly => true,
        require     => Package['locales'],
    }
    # Debian ships a locales-all package which has all locales pre-generated.
    # Ubuntu doesn't, so we're forced to generate them locally every time :(
    # lint:ignore:case_without_default
    case $::operatingsystem {
    # lint:endignore
        'Debian': {
            package { 'locales-all':
                ensure => present,
            }
        }
        'Ubuntu': {
            file { '/var/lib/locales/supported.d/all':
                ensure => link,
                source => '/usr/share/i18n/SUPPORTED',
                notify => Exec['locale-gen'],
            }
        }
    }
}
