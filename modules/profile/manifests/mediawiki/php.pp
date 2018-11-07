# === Class profile::mediawiki::php
#
# This class declares packages that make up Wikimedia's PHP7-based
# MediaWiki deployment stack. We'll be moving to this by mid-2018.
# See T172165
#
# overview of modules needed and their use:
#
# apcu - used by MediaWiki for local server caching
# bz2 - dumps
# curl - HTTP requests
# gd - ZeroBanner
# geoip - fundraising
# intl, mbstring, xml - MediaWiki dependencies
# memcached, mysql, redis - obvious from the name
# bcmath, gmp - various extensions and vendor libraries
#
class profile::mediawiki::php(
    Boolean $enable_fpm = hiera('profile::mediawiki::php::enable_fpm'),
    Optional[Hash] $fpm_config = hiera('profile::mediawiki::php::fpm_config', undef),
) {
    if os_version('debian == stretch') {
        apt::pin { 'php-wikidiff2':
            package  => 'php-wikidiff2',
            pin      => 'release a=stretch-backports',
            priority => '1001',
            before   => Package['php-wikidiff2'],
        }
    }

    # We're on 7.0 until we can give 7.2 a ride.
    $php_version = '7.0'

    $config_cli = {
        'include_path' => '".:/usr/share/php:/srv/mediawiki/php"',
        'error_log'    => 'syslog',
    }

    if $enable_fpm {
        $_sapis = ['cli', 'fpm']
        $_config = {
            'cli' => $config_cli,
            'fpm' => merge($config_cli, $fpm_config)
        }
    } else {
        $_sapis = ['cli']
        $_config = {
            'cli' => $config_cli,
        }
    }
    # Install the runtime
    class { '::php':
        ensure         => present,
        version        => $php_version,
        sapis          => $_sapis,
        config_by_sapi => $_config,
    }

    # Extensions that need no custom settings
    php::extension { [
        'apcu',
        'bcmath',
        'bz2',
        'curl',
        'gd',
        'geoip',
        'gmp',
        'intl',
        'luasandbox',
        'mbstring',
        'msgpack',
        'redis',
        'wikidiff2'
    ]:
        ensure => present
    }

    # Extensions that require configuration
    php::extension {
        'xml':
            priority => 15;
        'memcached':
            priority => 25,
            config   => {
                'extension'            => 'memcached.so',
                'memcached.serializer' => 'php',
            };
        'igbinary':
            config   => {
                'extension'       => 'igbinary.so',
                'compact_strings' => 'Off',
            };
        'mysqli':
            package_name => 'php-mysql';
        'dba':
            package_name => "php${php_version}-dba",
    }

    # Additional config files are needed by some extensions, add them
    # MySQL
    php::extension {
        default:
            package_name => '',;
        'pdo_mysql':
            ;
        'mysqlnd':
            priority => 10,
    }
    # XML
    php::extension{ [
        'dom',
        'simplexml',
        'xmlreader',
        'xmlwriter',
        'xsl',
        'wddx',
    ]:
        package_name => '',
    }

    ### FPM configuration
    # You can check all configuration options at
    # http://php.net/manual/en/install.fpm.configuration.php
    if $enable_fpm {
        class { '::php::fpm':
            ensure => present,
            config => {
                'emergency_restart_interval'  => '60s',
                'emergency_restart_threshold' => $facts['processors']['count'],
                'process.priority'            => -19,
            }
        }

        # This will add an fpm pool listening on port 8000
        # We only use 16 children for now, and the dynamic pm
        # as we still are in an experimental state
        # TODO: tune the parameters and switch back to the static pm
        php::fpm::pool { 'www':
            port   => 8000,
            config => {
                'pm'                        => 'dynamic',
                'pm.max_spare_servers'      => 10,
                'pm.min_spare_servers'      => 2,
                'pm.max_children'           => 16,
                'request_terminate_timeout' => 240,
            }
        }
    }
}
