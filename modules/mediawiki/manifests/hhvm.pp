# == Class: mediawiki::hhvm
#
# Configures HHVM to serve MediaWiki in FastCGI mode.
#
class mediawiki::hhvm {
    requires_os('ubuntu >= trusty')

    include ::hhvm::admin
    include ::hhvm::monitoring
    include ::hhvm::debug
    include ::mediawiki::hhvm::housekeeping

    include ::mediawiki::users

    # Derive HHVM's thread count by taking the smallest of:
    #  - the memory of the system divided by a typical thread memory allocation
    #  - processor count * 4 (we have hyperthreading)
    $max_threads = min(
        floor(to_bytes($::memorytotal) / to_bytes('120M')),
        $::processorcount*4)

    class { '::hhvm':
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
                    error_document500     => '/srv/mediawiki/errorpages/hhvm-fatal-error.php',
                    error_document404     => '/srv/mediawiki/errorpages/404.php',
                    request_init_document => '/srv/mediawiki/wmf-config/HHVMRequestInit.php',
                    thread_count          => $max_threads,
                    ip                    => '127.0.0.1',
                },
                pcre_cache_type => 'lru',
            },
        },
    }


    # furl is a cURL-like command-line tool for making FastCGI requests.
    # See `furl --help` for documentation and usage.

    file { '/usr/local/bin/furl':
        source => 'puppet:///modules/mediawiki/furl',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }


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


    # Use Debian's Alternatives system to mark HHVM as the default PHP
    # implementation for this system. This makes /usr/bin/php a symlink
    # to /usr/bin/hhvm.

    alternatives::select { 'php':
        path    => '/usr/bin/hhvm',
        require => Package['hhvm'],
        before  => Service['hhvm'],
    }

}
