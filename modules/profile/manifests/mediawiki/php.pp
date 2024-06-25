# === Class profile::mediawiki::php
#
# This class declares packages that make up Wikimedia's PHP7-based
# MediaWiki deployment stack.
# See T172165
#
# overview of modules needed and their use:
#
# apcu - used by MediaWiki for local server caching
# bz2 - dumps
# curl - HTTP requests
# gd - ZeroBanner
# intl, mbstring, xml - MediaWiki dependencies
# memcached, mysql, redis - obvious from the name
# bcmath, gmp - various extensions and vendor libraries
# yaml - SettingsLoader (T296331)
#
class profile::mediawiki::php(
    Boolean $enable_fpm = lookup('profile::mediawiki::php::enable_fpm'),
    Optional[Hash] $fpm_config = lookup('profile::mediawiki::php::fpm_config', {default_value => undef}),
    Optional[Stdlib::Port::User] $port = lookup('profile::php_fpm::fcgi_port', {default_value => undef}),
    String $fcgi_pool = lookup('profile::mediawiki::fcgi_pool', {default_value => 'www'}),
    Integer $request_timeout = lookup('profile::mediawiki::php::request_timeout', {default_value => 240}),
    String $apc_shm_size = lookup('profile::mediawiki::apc_shm_size'),
    # temporary, for php restarts
    String $cluster = lookup('cluster'),
    # Needed for wmerrors
    String $statsd = lookup('statsd'),
    # Allows to tune up or down the number of workers.
    Float $fpm_workers_multiplier = lookup('profile::mediawiki::php::fpm_workers_multiplier', {'default_value' => 1.5}),
    Boolean $enable_request_profiling = lookup('profile::mediawiki::php::enable_request_profiling', {'default_value' => false}),
    Optional[Boolean] $enable_php_core_dumps = lookup('profile::mediawiki::php:::enable_php_core_dumps', {'default_value' => false}),
    Integer $slowlog_limit = lookup('profile::mediawiki::php::slowlog_limit', {'default_value' => 15}),
    Boolean $phpdbg = lookup('profile::mediawiki::php::phpdbg', {'default_value' => false}),
    Array[Wmflib::Php_version] $php_versions = lookup('profile::mediawiki::php::php_versions'),
    Array[Wmflib::Php_version] $absented_php_versions = lookup('profile::mediawiki::php::absented_php_versions', {'default_value' => []}),
    Boolean $increase_open_files = lookup('profile::mediawiki::php::increase_open_files', {'default_value' => false}),
    Boolean $enable_php83_icu72 = lookup('profile::mediawiki::php::enable_php83_icu72', {'default_value' => false}),
    Boolean $enable_dogstatsd = lookup('profile::mediawiki::php::enable_dogstatsd', {'default_value' => true}),
){
    # The first listed php version is the default one
    $default_php_version = $php_versions[0]

    # Starting with Bookworm the Wikimedia APT repository uses the signed-by
    # notation, so component repositories targeting Bookworm must point at
    # the same keyring or apt raises a conflicting repo error. Mirror the
    # logic in the apt module (modules/apt/manifests/init.pp).
    if debian::codename::ge('bookworm') {
        $wikimedia_apt_keyfile = 'puppet:///modules/install_server/autoinstall/keyring/wikimedia-archive-keyring.gpg'
    } else {
        $wikimedia_apt_keyfile = undef
    }

    # Use component/php83 if php 8.3 is installed.
    if ('8.3' in $php_versions) {
        # The php83-icu72 component (php 8.3 built against ICU 72) is only
        # published for Bullseye, whose native ICU is 67. Bookworm ships ICU 72
        # natively, so disregard the flag there.
        $component_name = debian::codename() ? {
            'bookworm' => 'component/php83',
            'bullseye' => $enable_php83_icu72 ? {
                true    => 'component/php83-icu72',
                default => 'component/php83',
            }
        }
        apt::repository { 'wikimedia-php83':
            uri        => 'http://apt.wikimedia.org/wikimedia',
            dist       => "${facts['os']['distro']['codename']}-wikimedia",
            components => $component_name,
            keyfile    => $wikimedia_apt_keyfile,
            notify     => Exec['apt_update_php'],
            before     => Package['php8.3-common', 'php8.3-opcache']
        }

        if debian::codename::eq('bullseye') {
            # As per T386006, we need a PCRE 10.39 or higher for PHP 8.3
            # to work properly. On bullseye, we've backported bookworm's
            # 10.42 in order to satisfy that.
            $libpcre2_version = '10.42-1~wmf11+1'
            package { 'libpcre2-8-0':
                ensure  => $libpcre2_version,
                require => Apt::Repository['wikimedia-php83'],
                before  => Package['php8.3-common', 'php8.3-opcache']
            }
        }

        # Install explicitly php-common from the php83 component as the one
        # installed elsewhere misses.
        # Note that this is provided by the php-defaults source package, and
        # this reflects its versioning scheme. The WMF build revision differs
        # per Debian release, so pin per codename.
        $php_common_version = debian::codename() ? {
            'bookworm' => '2:94+wmf12u1',
            'bullseye' => $enable_php83_icu72 ? {
                true    => '2:94+wmf11u1+icu72u1',
                default => '2:94+wmf11u1',
            }
        }
        package { 'php-common':
            ensure  => $php_common_version,
            require => Exec['apt_update_php'],
            before  => Package['php8.3-common', 'php8.3-opcache']
        }
    } elsif ('8.3' in $absented_php_versions) {
        apt::repository { 'wikimedia-php83':
            ensure => absent,
        }
    }

    # Use component/php85 if php 8.5 is requested.
    if ('8.5' in $php_versions) {
        # FIXME: fail fast if debian::codename::ne('bookworm')
        apt::repository { 'wikimedia-php85':
            uri        => 'http://apt.wikimedia.org/wikimedia',
            dist       => 'bookworm-wikimedia',
            components => 'component/php85',
            keyfile    => $wikimedia_apt_keyfile,
            notify     => Exec['apt_update_php'],
            # PHP 8.5 removed the opcache package upstream
            before     => Package['php8.5-common']
        }

        # Install explicitly php-common from the php85 component.
        package { 'php-common':
            ensure  => '2:100+wmf12u1',
            require => Exec['apt_update_php'],
            before  => Package['php8.5-common']
        }
    } elsif ('8.5' in $absented_php_versions) {
        apt::repository { 'wikimedia-php85':
            ensure => absent,
        }
    }

    # remove all php versions we want to absent, completely.
    profile::mediawiki::php::absented_version{ $absented_php_versions: }

    # First installs can trip without this
    exec {'apt_update_php':
        command     => '/usr/bin/apt-get update',
        refreshonly => true,
    }

    $config_cli = {
        'include_path'           => '".:/usr/share/php"',
        'error_log'              => 'syslog',
        'pcre.backtrack_limit'   => 5000000,
        'date.timezone'          => 'UTC',
        'display_errors'         => 'stderr',
        'memory_limit'           => '500M',
        'error_reporting'        => 'E_ALL & ~E_STRICT',
        'mysql'                  => { 'connect_timeout' => 3 },
        'default_socket_timeout' => 60,
        'auto_prepend_file'      => '/srv/mediawiki/wmf-config/PhpAutoPrepend.php',
    }

    # Custom config for php-fpm
    # basic optimizations for opcache. See T206341
    $rlimit_core = $enable_php_core_dumps ? {
        true    => 'unlimited',
        default => '0',
    }
    $base_config_fpm = {
        'opcache.enable'                  => 1,
        'opcache.interned_strings_buffer' => 50,
        'opcache.memory_consumption'      => 300,
        'opcache.max_accelerated_files'   => 24000,
        'opcache.max_wasted_percentage'   => 10,
        'opcache.validate_timestamps'     => 1,
        'opcache.revalidate_freq'         => 10,
        'auto_prepend_file'               => '/srv/mediawiki/wmf-config/PhpAutoPrepend.php',
        'display_errors'                  => 0,
        'session.upload_progress.enabled' => 0,
        'enable_dl'                       => 0,
        'apc.shm_size'                    => $apc_shm_size,
        'rlimit_core'                     => $rlimit_core,
    }
    if $enable_fpm {
        $_sapis = ['cli', 'fpm']
        $_config = {
            'cli' => $config_cli,
            'fpm' => merge($config_cli, $base_config_fpm, $fpm_config)
        }
    } else {
        $_sapis = ['cli']
        $_config = {
            'cli' => $config_cli,
        }
    }
    # Install the runtime
    class { 'php':
        ensure         => present,
        versions       => $php_versions,
        sapis          => $_sapis,
        config_by_sapi => $_config,
        require        => Exec['apt_update_php'],
    }
    ### FPM configuration
    # You can check all configuration options at
    # http://php.net/manual/en/install.fpm.configuration.php
    if $enable_fpm {
        class { 'php::fpm':
            ensure => present,
            config => {
                'emergency_restart_interval'  => '60s',
                'emergency_restart_threshold' => $facts['processors']['count'],
                'process.priority'            => -19,
            }
        }

        # This will add an fpm pool listening on port $port
        # We want a minimum of 8 workers, and (we default to 1.5 * number of processors.
        # That number will be raised. Also move to pm = static as pm = dynamic caused some
        # edge-case spikes in p99 latency
        $num_workers = max(floor($facts['processors']['count'] * $fpm_workers_multiplier), 8)
        $versioned_port = php::fpm::versioned_port($port, $php_versions)

        $php_versions.each |$idx, $php_version| {
            $fpm_programname = php::fpm::programname($php_version)
            # Add systemd override for php-fpm, that should prevent a reload
            # if the fpm config files are broken.
            # This should prevent us from shooting our own foot as happened before.
            systemd::unit { "${fpm_programname}.service":
                ensure   => present,
                content  => template('profile/mediawiki/php-fpm-systemd-override.conf.erb'),
                override => true,
                restart  => false,
            }
            # PHP-fpm pools. We replace the default one to avoid puppet's management
            # of the pools.d directory to cause moments where php-fpm is incorrectly
            # configured.
            $pool_name = "${fcgi_pool}-${php_version}"
            php::fpm::pool { $pool_name:
                filename => 'www',
                port     => $versioned_port[$php_version],
                version  => $php_version,
                config   => {
                    'pm'                        => 'static',
                    'pm.max_children'           => $num_workers,
                    'request_terminate_timeout' => $request_timeout,
                    'request_slowlog_timeout'   => $slowlog_limit,
                }
            }

            # Send logs locally to /var/log/php7.x-fpm/error.log
            # Please note: this replaces the logrotate rule coming from the package,
            # because we use syslog-based logging. This will also prevent an fpm reload
            # for every logrotate run.
            systemd::syslog { $fpm_programname:
                base_dir     => '/var/log',
                owner        => 'www-data',
                group        => 'wikidev',
                readable_by  => 'group',
                log_filename => 'error.log'
            }
        }
    }

    # Extensions that need no custom settings

    # First, extensions provided as core extensions; these are version-specific
    # and are provided as php$version-$extension
    $core_extensions =  [
        'bcmath',
        'bz2',
        'curl',
        'gd',
        'gmp',
        'intl',
        'mbstring',
        'zip',
    ]
    php::extension { $core_extensions:
        versioned_packages => true,
    }

    # Extensions that we can simply install, without additional configuration,
    # version filtering, etc. These use version-specific package names, like
    # core extensions (php$version-$extension).
    $simple_extensions = [
        'apcu',
        'msgpack',
        'redis',
        'luasandbox',
        'wikidiff2',
        'yaml',
    ]
    php::extension { $simple_extensions:
        versioned_packages => true,
    }

    # The uuid extension is only needed on PHP 8.1 and later (T373752).
    php::extension{ 'uuid':
        versions           => $php_versions.filter |$v| { versioncmp($v, '8.1') >= 0 },
        versioned_packages => true,
    }

    # Extensions that require configuration.
    # Group 1: extensions that only have version-specific packages.
    $mysql_package_overrides = $php_versions.map |$v| {{$v => "php${v}-mysql"}}.reduce({}) |$m, $val| {$m.merge($val)}
    php::extension {
        'xml':
            versioned_packages => true,
            priority           => 15;
        'mysqli':
            package_overrides => $mysql_package_overrides,
            config            => {
                'extension'                 => 'mysqli.so',
                'mysqli.allow_local_infile' => 'Off',
            };
        'dba':
            versioned_packages => true,
    }

    php::extension {
        'memcached':
            versioned_packages => true,
            priority           => 25,
            config             => {
                'extension'                   => 'memcached.so',
                'memcached.serializer'        => 'php',
                'memcached.store_retry_count' => '0'
            };
        'igbinary':
            versioned_packages => true,
            config             => {
                'extension'                => 'igbinary.so',
                'igbinary.compact_strings' => 'Off',
            };
    }

    # Additional config files are needed by some extensions, add them
    # MySQL
    php::extension {
        default:
            install_packages => false,;
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
    ]:
        install_packages => false,
    }

    # Debug package
    $php_versions.map |$v| {
        package { "php${v}-phpdbg":
            ensure  => $phpdbg.bool2str('installed', 'absent'),
            require => Exec['apt_update_php']
        }
    }

    # Set up request profiling (T206152, see also T253547)
    $profiling_ensure = $enable_request_profiling ? {
        true    => 'present',
        default => 'absent'
    }

    php::extension { 'xhprof':
        ensure             => $profiling_ensure,
        versioned_packages => true,
        priority           => 30,
        config             => {
            'extension' => 'xhprof.so',
            }
    }

    # Install excimer, our php profiler. Please note this is not a single
    # request profiler, it is rather a sampling profiler. Thus, it is active on
    # all appservers and not just on the ones that allow running profiling.
    php::extension { 'excimer':
        versioned_packages => true,
    }

    # Select the default intepreter to the default (first listed) php version.
    $cli_path = "/usr/bin/php${default_php_version}"
    $pkg = "php${default_php_version}-cli"
    alternatives::select { 'php':
        path    => $cli_path,
        require => Package[$pkg],
    }

    ## Install wmerrors, on fpm only.
    if $enable_fpm {
        php::extension { 'wmerrors':
            versioned_packages => true,
            sapis              => ['fpm'],
            config             => {
                'extension'                  => 'wmerrors.so',
                'wmerrors.error_script_file' => '/etc/php/php7-fatal-error.php',
                'wmerrors.enabled'           => true,
            },
        }
        file { '/etc/php/php7-fatal-error.php':
            ensure  => present,
            mode    => '0444',
            owner   => 'root',
            group   => 'root',
            source  => 'puppet:///modules/profile/mediawiki/php/php7-fatal-error.php',
            require => Php::Extension['wmerrors'],
        }

        $statsd_parts = split($statsd, ':')
        $statsd_host = $statsd_parts[0]
        $statsd_port = $statsd_parts[1]

        file { '/etc/php/error-params.php':
            ensure  => present,
            mode    => '0444',
            owner   => 'root',
            group   => 'root',
            content => template('profile/mediawiki/error-params.php.erb'),
            require => Php::Extension['wmerrors'],
        }
    }
}
