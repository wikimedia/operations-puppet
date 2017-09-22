# == Class: mediawiki::hhvm
#
# Configures HHVM to serve MediaWiki in FastCGI mode.
#
class mediawiki::hhvm {
    include ::hhvm::admin
    include ::hhvm::monitoring
    include ::hhvm::debug
    include ::mediawiki::hhvm::housekeeping

    include ::mediawiki::users

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

    class { '::hhvm':
        # lint:ignore:arrow_alignment
        user          => $::mediawiki::users::web,
        group         => $::mediawiki::users::web,
        fcgi_settings => {
            hhvm => {
                xenon          => {
                    period => to_seconds('10 minutes'),
                },
                error_handling => {
                    call_user_handler_on_fatals => true,
                },
                server         => {
                    source_root           => '/srv/mediawiki/docroot',
                    error_document500     => '/etc/hhvm/fatal-error.php',
                    error_document404     => '/srv/mediawiki/errorpages/404.php',
                    request_init_document => '/srv/mediawiki/wmf-config/HHVMRequestInit.php',
                    thread_count          => $max_threads,
                    ip                    => '127.0.0.1',
                },
                pcre_cache_type => 'lru',
            },
            curl => {
                namedPools   => 'cirrus-eqiad,cirrus-codfw',
                # ugly hack to work around colision in the hash
                'namedPools.cirrus-codfw' => {
                    size => '20',
                },
                'namedPools.cirrus-eqiad' => {
                    size => '20',
                },
            },
        },
        cli_settings => {
            curl => {
                namedPools => 'cirrus-eqiad,cirrus-codfw',
            },
        },
        malloc_arenas => $malloc_arenas,
        # lint:endignore
    }


    # furl is a cURL-like command-line tool for making FastCGI requests.
    # See `furl --help` for documentation and usage.

    file { '/usr/local/bin/furl':
        source => 'puppet:///modules/mediawiki/furl',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    file { '/etc/hhvm/fatal-error.php':
        source  => 'puppet:///modules/mediawiki/hhvm-fatal-error.php',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => File['/etc/hhvm'],
        before  => Service['hhvm'],
    }

    if os_version('ubuntu >= trusty') {
        # Provision an Upstart task (a short-running process) that runs
        # when HHVM is started and that warms up the JIT by repeatedly
        # requesting URLs read from /etc/hhvm/warmup.urls.

        $warmup_urls = [ 'http://en.wikipedia.org/wiki/Special:Random' ]

        file { '/etc/hhvm/warmup.urls':
            content => join($warmup_urls, "\n"),
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
        }

        file { '/etc/init/hhvm-warmup.conf':
            source  => 'puppet:///modules/mediawiki/hhvm-warmup.conf',
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            require => File['/usr/local/bin/furl', '/etc/hhvm/warmup.urls'],
            before  => Service['hhvm'],
        }
    }

    # Note: the warmup process should be revisited and is thus not implemented on
    # Debian/systemd at the moment.

    # Use Debian's Alternatives system to mark HHVM as the default PHP
    # implementation for this system. This makes /usr/bin/php a symlink
    # to /usr/bin/hhvm.

    alternatives::select { 'php':
        path    => '/usr/bin/hhvm',
        require => Package['hhvm'],
        before  => Service['hhvm'],
    }

}
