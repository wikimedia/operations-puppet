# == Class contint::packages::php
class contint::packages::php {

    include ::mediawiki::packages::php5

    require_package( [
        'php5-dev',  # phpize
        'php5-ldap',  # OpenStackManager/LdapAuthentication T125158
        'php5-gd',
        'php5-gmp',
        # mcrypt is used by fundraising's CiviCRM setup, deprecated in PHP 7
        'php5-mcrypt',
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
            'php7.0-gmp',
            # missing geoip
            'php7.0-intl',
            'php-memcached',
            'php7.0-mysql',
            'php-redis',
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
            'php-imagick',
            'php-tideways',
            # for phan (T132636)
            'php-ast',
            ]:
            ensure  => latest,
            require => Apt::Repository['sury-php'],
        }
    }

    # PHP Extensions dependencies (mediawiki/php/*.git)
    package { [
        'libthai-dev',      # wikidiff2
        'luajit',           # luasandbox
        'liblua5.1.0-dev',  # luasandbox
    ]:
        ensure => present
    }

}
