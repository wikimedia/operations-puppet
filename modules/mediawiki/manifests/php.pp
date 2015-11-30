# == Class: mediawiki::php
#
# Packages and .ini files for PHP5 extensions.
#
class mediawiki::php {
    include ::mediawiki::packages

    if os_version('ubuntu >= trusty || debian >= Jessie') {
        $php_module_conf_dir = '/etc/php5/mods-available'
        mediawiki::php_enmod { ['fss']: }
    } else {
        $php_module_conf_dir = '/etc/php5/conf.d'
    }

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
    }

    if os_version('ubuntu precise') {
        file { '/etc/php5/conf.d/igbinary.ini':
            source  => 'puppet:///modules/mediawiki/php/igbinary.ini',
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            require => Package['php5-igbinary'],
        }

        file { '/etc/php5/conf.d/wmerrors.ini':
            content => template('mediawiki/php/wmerrors.ini.erb'),
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            require => Package['php5-wmerrors'],
        }

        file { '/etc/php5/conf.d/apc.ini':
            source  => 'puppet:///modules/mediawiki/php/apc.ini',
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            require => Package['php-apc'],
        }
    }
}
