# === Class mediawiki::packages::php7
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
#
class profile::mediawiki::php() {
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

    # Install the runtime
    class { '::php':
        ensure         => present,
        version        => $php_version,
        sapis          => ['cli'],
        config_by_sapi => {'cli' => $config_cli}
    }

    # Extensions that need no custom settings
    php::extension { [
        'apcu',
        'bz2',
        'curl',
        'gd',
        'geoip',
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
}
