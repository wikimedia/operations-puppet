# == Class: mediawiki::php
#
# Packages and .ini files for PHP extensions
#
class mediawiki::php {
    include ::mediawiki::packages::php7

    mediawiki::php_enmod { ['mail']: }

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
}
