# == Class: profile::mediawiki::hhvm
#
# Configures HHVM to serve MediaWiki in FastCGI mode.
#
# === Parameters
# [*user*]
#   The user to run HHVM as
#
# [*extra_fcgi*]
#   Supplemental settings for FastCGI mode
#
# [*extra_cli*]
#   Supplemental settings for CLI mode.
#
# [*statsd*]
#   Host and port for a StatsD server.
#
class profile::mediawiki::hhvm(
    String $user = hiera('mediawiki::users::web', 'www-data'),
    Hash $extra_fcgi = hiera('mediawiki::hhvm::extra_fcgi', {}),
    Hash $extra_cli = hiera('mediawiki::hhvm::extra_cli', {}),
    $statsd = hiera('statsd')
) {
    class { 'hhvm::debug': }

    # Derive HHVM's thread count by taking the smallest of:
    #  - the memory of the system divided by a typical thread memory allocation
    #  - processor count * 4 (we have hyperthreading)
    $max_threads = min(
        floor(to_bytes($::memorysize) / to_bytes('120M')),
        $::processorcount*4)

    # Number of malloc arenas to use, see T151702
    # HHVM defaults to 1
    # We want to have the same number of arenas as our threads
    $malloc_arenas = $max_threads

    $fcgi_settings =  {
        # See https://docs.hhvm.com/hhvm/configuration/INI-settings
        # https://secure.php.net/ini.core#ini.auto-prepend-file
        auto_prepend_file => '/srv/mediawiki/wmf-config/PhpAutoPrepend.php',
        hhvm              =>
        {
            xenon             => {
                period => to_seconds('5 minutes'),
            },
            enable_reusable_tc => true,
            error_handling     => {
                call_user_handler_on_fatals => true,
            },
            server             => {
                source_root           => '/srv/mediawiki/docroot',
                error_document500     => '/etc/hhvm/fatal-error.php',
                error_document404     => '/srv/mediawiki/errorpages/404.php',
                # Currently testing on Beta Cluster: auto_prepend_file (T180183)
                request_init_document => '/srv/mediawiki/wmf-config/HHVMRequestInit.php',
                thread_count          => $max_threads,
                ip                    => '127.0.0.1',
            },
            pcre_cache_type    => 'lru',
            mysql              => {
                connect_timeout => 3000,
            },
        },
        curl              => {
            namedPools   => 'cirrus-eqiad,cirrus-codfw',
            # ugly hack to work around colision in the hash
            'namedPools.cirrus-codfw' => {
                size => '20',
            },
            'namedPools.cirrus-eqiad' => {
                size => '20',
            },
        },
    }

    $cli_settings = {
        curl => {
            namedPools => 'cirrus-eqiad,cirrus-codfw',
        },
        hhvm => { mysql => { connect_timeout => 3000, } },
    }

    class { '::hhvm':
        user          => $::mediawiki::users::web,
        group         => $::mediawiki::users::web,
        fcgi_settings => deep_merge($fcgi_settings, $extra_fcgi),
        cli_settings  => deep_merge($cli_settings, $extra_cli),
        malloc_arenas => $malloc_arenas,
    }


    # furl is a cURL-like command-line tool for making FastCGI requests.
    # See `furl --help` for documentation and usage.

    file { '/usr/local/bin/furl':
        source => 'puppet:///modules/mediawiki/furl',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    $statsd_parts = split($statsd, ':')
    $statsd_host = $statsd_parts[0]
    $statsd_port = $statsd_parts[1]

    file { '/etc/hhvm/fatal-error.php':
        content => template('mediawiki/hhvm-fatal-error.php.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => File['/etc/hhvm'],
        before  => Service['hhvm'],
    }


    # Use Debian's Alternatives system to mark HHVM as the default PHP
    # implementation for this system. This makes /usr/bin/php a symlink
    # to /usr/bin/hhvm.

    alternatives::select { 'php':
        path    => '/usr/bin/hhvm',
        require => Package['hhvm'],
        before  => Service['hhvm'],
    }

    # This command is useful prune the hhvm bytecode cache from old tables that
    # are just left around

    file { '/usr/local/sbin/hhvm_cleanup_cache':
        source => 'puppet:///modules/profile/mediawiki/hhvm/cleanup_cache',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }
}
