# == Class contint::packages::php
class contint::packages::php {

    package { [
        'php5-dev',  # phpize
        'php5-ldap',  # OpenStackManager/LdapAuthentication T125158
        'php5-gd',
        'php5-pgsql',
        'php5-sqlite',
        'php5-tidy',
        'php5-xdebug',
        ]:
        ensure => present,
    }
    package { [
        'php5-parsekit',
        ]:
        ensure => absent,
    }

    if os_version('ubuntu < trusty') {
        # Disable APC entirely it gets confused when files changes often
        file { '/etc/php5/conf.d/apc.ini':
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            source  => 'puppet:///modules/contint/disable-apc.ini',
            require => Package['php-apc'],
        }
    }

    if os_version('ubuntu >= trusty || debian >= jessie') {
        exec { '/usr/bin/apt-get -y build-dep hhvm':
            onlyif => '/usr/bin/apt-get -s build-dep hhvm | /bin/grep -Pq "will be (installed|upgraded)"',
        }
        package { ['hhvm-dev']:
            ensure => present,
        }


    }

}
