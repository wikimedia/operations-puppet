# == Class: mediawiki::php
#
# Packages and .ini files for PHP5 or PHP7 extensions.
#
class mediawiki::php {
    if  os_verson('debian >= stretch') {
        $php_module_conf_dir = '/etc/php/7.0/mods-available'
        mediawiki::php_enmod { ['mail']:
            modspath => $php_module_conf_dir,
            enmod    => 'phpenmod',
        }

        file { '/etc/php/7.0/apache2':
            ensure => directory,
            owner  => 'root',
            group  => 'root',
            mode   => '0444',
        }

        file { '/etc/php/7.0/apache2/php.ini':
            # need to see if there are php7 changes we want here
            source => 'puppet:///modules/mediawiki/php/php.ini',
            owner  => 'root',
            group  => 'root',
            mode   => '0444',
        }

        file { '/etc/php/7.0/cli/php.ini':
            # need to see if there are php7 changes we want here
            source => 'puppet:///modules/mediawiki/php/php.ini.cli',
            owner  => 'root',
            group  => 'root',
            mode   => '0444',
        }

        file { "${php_module_conf_dir}/mail.ini":
            ensure => absent,
        }
    } else {
        $php_module_conf_dir = '/etc/php5/mods-available'
        mediawiki::php_enmod { ['mail']: }

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

            file { "${php_module_conf_dir}/mail.ini":
                ensure  => absent,
                require => Package['php-mail'],
            }
        }
    }
}
