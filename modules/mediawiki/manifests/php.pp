# == Class: mediawiki::php
#
# Packages and .ini files for PHP5 or PHP7 extensions.
#
class mediawiki::php {
    if os_version('ubuntu == trusty') {
        include ::mediawiki::packages::php5
    }
    elsif os_version('debian >= stretch') {
        include ::mediawiki::packages::php7
    }

    mediawiki::php_enmod { ['mail']: }

    if  os_version('debian >= stretch') {
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

    } else {
        # Only install PHP configuration files on Trusty, jessie
        # no longer installs Zend PHP
        if os_version('ubuntu == trusty') {
            file { '/etc/php5/apache2/php.ini':
                source  => 'puppet:///modules/mediawiki/php/php.ini',
                owner   => 'root',
                group   => 'root',
                mode    => '0444',
                # libapache2-mod-php5 actually provides the /etc/php5/apache2
                # directory, but we only install it as a side effect of php5-dbg.
                require => Package['php5-dbg'],
            }

            file { '/etc/php5/cli/php.ini':
                source  => 'puppet:///modules/mediawiki/php/php.ini.cli',
                owner   => 'root',
                group   => 'root',
                mode    => '0444',
                require => Package['php5-cli'],
            }

        }
    }
}
