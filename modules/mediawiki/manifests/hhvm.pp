# == Class: mediawiki::hhvm
#
# Configures HHVM to serve MediaWiki in FastCGI mode.
#
# [*experimental_features*]
#   Boolean parameter. Can be used on single hosts to enable
#   experimental features.
class mediawiki::hhvm($experimental_features = false) {
    requires_ubuntu('>= trusty')

    include ::hhvm::admin
    include ::hhvm::monitoring
    include ::hhvm::debug

    include ::mediawiki::users
    include ::mediawiki::hhvm::housekeeping

    # Derive HHVM's thread count by taking the smallest of:
    #  - the memory of the system divided by a typical thread memory allocation
    #  - processor count * 4 (we have hyperthreading)
    $max_threads = min(
        floor(to_bytes($::memorytotal) / to_bytes('120M')),
        $::processorcount*4)


    $fcgi_standard_settings = {
        error_handling => {
            call_user_handler_on_fatals => true,
        },
        server         => {
            source_root           => '/srv/mediawiki/docroot',
            error_document500     => '/srv/mediawiki/hhvm-fatal-error.php',
            error_document404     => '/srv/mediawiki/w/404.php',
            request_init_document => '/srv/mediawiki/wmf-config/HHVMRequestInit.php',
            thread_count          => $max_threads,
        },
    }

    $experimental_settings = {
        server => {
            # limit threads to #cpus until this many requests; reduces
            # starvation of threads that are JIT-compiling
            warmup_throttle_request_count     => 1000,
            # Limit number of child processes running at once
            light_process_count               => 10,
            # JobQueueWorker::dequeueMaybeExpiredImpl will by default
            # wait() indefinitely; if set, it will timeout after
            # thread_drop_cache_timeout_seconds seconds and call
            # DropCachePolicy::dropCache()
            thread_drop_cache_timeout_seconds => 5,
            #If this is set to true, and drop cache timeout gets
            #triggered, it will flush the thread stack upon killing
            #it; I don't really see why one would want to set this to
            #false if the other is different than 0
            thread_drop_stack                 => true,
        },
        http   => {
            # Log http client requests taking too much time
            slow_query_threshold              => 10000,
        },
        stats  => {
            enable        => true,
            web           => true,
            memory        => true,
            memcache      => true,
            sql           => true,
            slot_duration => 30,
            max_slot      => 10,
        }
    }

    if ($experimental_features) {
        $fcgi_settings = deep_merge(
            $fcgi_standard_settings,
            $experimental_settings)
    }
    else {
        $fcgi_settings = $fcgi_standard_settings
    }


    class { '::hhvm':
        user          => 'apache',
        group         => 'apache',
        fcgi_settings => {
            hhvm => $fcgi_settings,
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
