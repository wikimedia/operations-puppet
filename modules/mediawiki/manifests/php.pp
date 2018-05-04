# == Class: mediawiki::php
#
# Packages and .ini files for PHP5 or PHP7 extensions.
#
class mediawiki::php {
    if os_version('debian >= stretch') {
        include ::mediawiki::packages::php7
    }

    mediawiki::php_enmod { ['mail']: }

    if os_version('debian >= stretch') {
        file { '/etc/php/7.0/fpm':
            ensure => directory,
            owner  => 'root',
            group  => 'root',
            mode   => '0444',
        }

        file { '/etc/php/7.0/fpm/php.ini':
            source => 'puppet:///modules/mediawiki/php/php7.ini',
            owner  => 'root',
            group  => 'root',
            mode   => '0444',
        }

        file { '/etc/php/7.0/cli/php.ini':
            source => 'puppet:///modules/mediawiki/php/php7.ini.cli',
            owner  => 'root',
            group  => 'root',
            mode   => '0444',
        }

        file { '/etc/php/7.0/mods-available/mail.ini':
            ensure => absent,
        }
    } else {
        file { '/etc/php5/mods-available/mail.ini':
            ensure  => absent,
            require => Package['php-mail'],
        }
    }
}
