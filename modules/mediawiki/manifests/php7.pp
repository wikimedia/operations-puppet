# == Class: mediawiki::php
#
# Packages and .ini files for PHP7 extensions.
#
class mediawiki::php {
    include ::mediawiki::packages

    $php_module_conf_dir = '/etc/php7/mods-available'
    mediawiki::php_enmod { ['mail']: }

    file { '/etc/php7/apache2/php.ini':
        source  => 'puppet:///modules/mediawiki/php7/php.ini',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        # libapache2-mod-php7 actually provides the /etc/php7/apache2
        # directory, but we only install it as a side effect of php-dbg.
        require => Package['php-dbg'],
    }

    file { '/etc/php7/cli/php.ini':
        source  => 'puppet:///modules/mediawiki/php/php.ini.cli',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => Package['php7.0-cli'],
    }

    file { "${php_module_conf_dir}/mail.ini":
        ensure  => absent,
        require => Package['php-mail'],
    }
}
