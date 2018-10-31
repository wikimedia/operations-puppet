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
    Enum['7.0', '7.2'] $php_version = hiera('profile::mediawiki::php::php_version', '7.0')
) {
    if os_version('debian == stretch') {
        # We get our packages for our repositories again
        file { '/etc/apt/preferences.d/php_wikidiff2.pref':
            ensure => absent,
            notify => Exec['apt_update_php'],
        }
        # Use php7.2 from Ondrej Sury's repository.
        if $php_version == '7.2' {
            apt::repository { 'wikimedia-php72':
                uri        => 'http://apt.wikimedia.org/wikimedia',
                dist       => "${::lsbdistcodename}-wikimedia",
                components => 'thirdparty/php72',
                notify     => Exec['apt_update_php'],
                before     => Package["php${php_version}-common", "php${php_version}-opcache"]
            }
        }

        # First installs can trip without this
        exec {'apt_update_php':
            command     => '/usr/bin/apt-get update',
            refreshonly => true,
        }
    }

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

    # First, extensions provided as core extensions; these are version-specific
    # and are provided as php$version-$extension
    #
    $core_extensions =  [
        'bcmath',
        'bz2',
        'curl',
        'gd',
        'gmp',
        'intl',
        'mbstring',
    ]

    $core_extensions.each |$extension| {
        php::extension { $extension:
            package_name => "php${php_version}-${extension}"
        }
    }
    # Extensions that are installed with package-name php-$extension and, based
    # on the php version selected above, will install the proper extension
    # version based on apt priorities.
    # php-luasandbox and  php-wikidiff2 are special cases as the package is *not*
    # compatible with all supported PHP versions.
    # Technically, it would be needed to inject ensure => latest in the packages,
    # but we prefer to handle the transitions with other tools than puppet.
    php::extension { [
        'apcu',
        'geoip',
        'msgpack',
        'redis',
        'luasandbox',
        'wikidiff2',
    ]:
        ensure => present
    }

    # Extensions that require configuration.
    php::extension {
        'xml':
            package_name => "php${php_version}-xml",
            priority     => 15;
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
            package_name => "php${php_version}-mysql";
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
