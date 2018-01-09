# == Class contint::packages::php
class contint::packages::php {

    if os_version('ubuntu == trusty || debian == jessie') {
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

      exec { 'disable php5-xdebug on cli':
          command => '/usr/sbin/php5dismod -s cli xdebug',
          onlyif  => '/usr/sbin/php5query -s cli -m xdebug',
          require => Package['php5-xdebug'],
      }

      package { [
          'php5-parsekit',
          ]:
          ensure => absent,
      }
    }

    if os_version('debian >= jessie') {
        $php7_packages = [
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
            'php-xdebug',
            'php7.0-phpdbg',  # php70-phpdbg -qrr ...
            # ..and these are part of php5-common,
            # but now are separate packages
            'php7.0-bcmath',
            'php7.0-bz2',
            'php7.0-mbstring',
            'php7.0-xml',
            'php-imagick',
            'php-tideways',
            # for phan (T132636)
            'php-ast',
        ]

      exec { 'disable php-xdebug on cli':
          command => '/usr/sbin/phpdismod -v 7.0 -s cli xdebug',
          onlyif  => '/usr/sbin/phpquery -v 7.0 -s cli -m xdebug',
          require => Package['php-xdebug'],
      }

    }

    if os_version('debian >= stretch') {
        package { $php7_packages :
            ensure  => latest,
        }
    }

    if os_version('debian == jessie') {
        package { $php7_packages :
            ensure  => latest,
            require => [
                Apt::Repository['sury-php'],
                Exec['apt-get update'],
            ],
        }

        apt::repository { 'jessie-ci-php55':
            uri        => 'http://apt.wikimedia.org/wikimedia',
            dist       => 'jessie-wikimedia',
            components => 'component/ci',
            source     => false,
        }

        package { [
            'php5.5-cli',
            'php5.5-common',
            'php5.5-curl',
            'php5.5-dev',
            'php5.5-gd',
            'php5.5-gmp',
            'php5.5-intl',
            'php5.5-ldap',
            'php5.5-luasandbox',
            'php5.5-mbstring',
            'php5.5-mcrypt',
            'php5.5-mysql',
            'php5.5-redis',
            'php5.5-sqlite3',
            'php5.5-tidy',
            'php5.5-xml',
            'php5.5-xsl',
            'php5.5-zip',
            ]:
            ensure  => present,
            require => [
                Apt::Repository['jessie-ci-php55'],
                Exec['apt-get update'],
            ],
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
