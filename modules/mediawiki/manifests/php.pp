# == Class: mediawiki::php
#
# Packages and .ini files for PHP5 extensions.
#
class mediawiki::php {
    include ::mediawiki::packages
    requires_os('ubuntu >= trusty || Debian >= jessie')

    $php_module_conf_dir = '/etc/php5/mods-available'
    mediawiki::php_enmod { ['fss', 'mail']: }

    file { '/etc/php5/apache2/php.ini':
        source  => 'puppet:///modules/mediawiki/php/php.ini',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => Package['php5-common'],
    }

    file { '/etc/php5/cli/php.ini':
        source  => 'puppet:///modules/mediawiki/php/php.ini.cli',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => Package['php5-cli'],
    }

    file { "${php_module_conf_dir}/fss.ini":
        source  => 'puppet:///modules/mediawiki/php/fss.ini',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => Package['php5-fss'],
    }

    file { "${php_module_conf_dir}/mail.ini":
        ensure  => absent,
        require => Package['php-mail'],
    }
}
