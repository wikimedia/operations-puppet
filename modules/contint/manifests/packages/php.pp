# == Class contint::packages::php
class contint::packages::php {

    require_package( [
        'php5-dev',  # phpize
        'php5-ldap',  # OpenStackManager/LdapAuthentication T125158
        'php5-gd',
        'php5-pgsql',
        'php5-sqlite',
        'php5-tidy',
        'php5-xdebug',
        # MediaWikiFarm extension
        # phpdocumentor/template-zend
        'php5-xsl',
    ] )
    package { [
        'php5-parsekit',
        ]:
        ensure => absent,
    }

    if os_version('debian == jessie') {
        package { [
            # PHP 7.0 version of packages in mediawiki::packages::php5
            'php7.0-cli',
            'php7.0-common',
            # Note: Missing luasandbox and wikidiff2
            # PHP extensions
            'php7.0-curl',
            # missing geoip
            'php7.0-intl',
            # missing memcached
            'php7.0-mysql',
            # missing redis
            'php7.0-xmlrpc',
            # CI packages from above
            'php7.0-dev',
            'php7.0-ldap',
            'php7.0-gd',
            'php7.0-pgsql',
            'php7.0-sqlite3',
            'php7.0-tidy',
            # xdebug s provided by sury as php-xdebug but we are using phpdbg
            # which is faster for code coverage
            'php7.0-phpdbg',  # php70-phpdbg -qrr ...
            # ..and these are part of php5-common,
            # but now are separate packages
            'php7.0-bcmath',
            'php7.0-mbstring',
            'php7.0-xml',
            ]:
            ensure  => latest,
            require => Apt::Repository['sury-php'],
        }
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

    package { 'libcurl4-gnutls-dev':
        # Conflict with HHVM build dependency libcurl4-openssl-dev.
        # Was For pycurl which now build with openssl just fine.
        ensure =>  absent,
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
