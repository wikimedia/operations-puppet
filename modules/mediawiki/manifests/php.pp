# == Class: mediawiki::php
#
# Packages and .ini files for PHP5 extensions.
#
class mediawiki::php {
    include ::mediawiki::packages
    requires_os('ubuntu >= trusty || Debian >= jessie')

    $php_module_conf_dir = '/etc/php5/mods-available'
    mediawiki::php_enmod { ['mail']: }

    # Only install PHP configuration files on Trusty, jessie onwards
    # no longer installs Zend PHP
    if os_version('ubuntu == trusty') {
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
    }

    file { "${php_module_conf_dir}/mail.ini":
        ensure  => absent,
        require => Package['php-mail'],
    }
}
