# == Class: mediawiki::php
#
# Packages and .ini files for PHP5 or PHP7 extensions.
#
class mediawiki::php {
    # We do not install fully php5 on the appservers with jessie.
    # We do on trusty (for supporting dumps, historically) and on stretch we do install it
    # again as we're moving back to php.
    if os_version('debian != jessie') {
        class { '::php':
            ensure     => present,
            cli_config => { 'include_path' => '.:/usr/share/php:/srv/mediawiki/php'}
        }
        if os_version('ubuntu == trusty') {
            include ::mediawiki::packages::php5
        }
        elsif os_version('debian >= stretch') {
            include ::mediawiki::packages::php7
        }
    }

    # Please note this is useless, as we should rather disable the module as we remove the
    # reference. Debian/Ubuntu will still DTRT, but we should remove this.
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

        file { '/etc/php/7.0/mods-available/mail.ini':
            ensure => absent,
        }
    } else {
        # Only install PHP configuration files on Trusty, jessie
        # still installs Zend PHP (via mediawiki::packages) but we decided to
        # leave it broken because at the time we hoped to get rid of Zend.
        # Since it's not going to be the case, we might change this manifest, or just
        # ignore the issue until we're migrated away from trusty/jessie.
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
        }
        file { '/etc/php5/mods-available/mail.ini':
            ensure  => absent,
            require => Package['php-mail'],
        }
    }
}
