# == Class: hhvm
#
# This module provisions HHVM -- an open-source, high-performance
# virtual machine for PHP.
#
# The layout of configuration files in /etc/hhvm is as follows:
#
#   /etc/hhvm
#   |__ php.ini      # Settings for CLI mode
#   |__ fcgi.ini     # Settings for FastCGI mode
#
# The CLI configs are located in the paths HHVM automatically loads by
# default. This makes it easy to invoke HHVM from the command line,
# because no special arguments are required.
#
# The exact purpose of certain options is a little mysterious. The
# documentation is getting better, but expect to have to dig around in
# the source code.
#
#
# === Logging
#
# This module configures HHVM to write to syslog, and it configures
# rsyslogd(8) to write HHVM's log messages to /var/log/hhvm/error.log.
# HHVM is also configured to write stack traces to the same directory.
#
#   /var/log/hhvm
#   |__ error.log
#   |__ stacktrace.NNN.log.YYYYMMDD, ...
#
#
# === Parameters
#
# [*user*]
#   Run the FastCGI server as this user (default: 'www-data').
#
# [*group*]
#   Run the FastCGI server as this group (default: 'www-data').
#
# [*cli_settings*]
#   A hash of php.ini settings for CLI mode. These will override
#   the defaults (declared below).
#
# [*fcgi_settings*]
#   Ditto, except for FastCGI mode.
#
# === Examples
#
#  class { 'hhvm':
#    user          => 'apache',
#    group         => 'wikidev',
#    fcgi_settings => {
#      'hhvm' => { server => { source_root => '/srv/mediawiki' } },
#    },
#  }
#
class hhvm(
    $user          = 'www-data',
    $group         = 'www-data',
    $fcgi_settings = {},
    $cli_settings  = {},
    $base_jit_size = to_bytes('400 Mb'),
) {
    requires_os('ubuntu >= trusty')


    ## Packages

    package { 'hhvm':
        ensure => present,
    }

    package { [ 'hhvm-luasandbox', 'hhvm-tidy', 'hhvm-wikidiff2' ]:
        ensure => present,
    }


    ## Settings

    ### JIT

    # HHVM's translation cache is a slab of memory allocated in the
    # bottom 2 GiB for caching translated code. It is partitioned into
    # several differently-sized blocks of memory that group code blocks
    # by frequency of execution.
    #
    # You can check TC memory usage stats via the /vm-tcspace end-point
    # of the admin server.
    #
    # A ratio of 1 : 0.33 : 0.33 for a : a_cold : a_frozen is good
    # in our use-case.

    $a_size        = $base_jit_size
    $a_cold_size   = 0.33 * $base_jit_size
    $a_frozen_size = 0.33 * $base_jit_size


    $common_defaults = {
        date         => { timezone => 'UTC' },
        include_path => '.:/usr/share/php',

        # HHVM specific
        hhvm         => {
            dynamic_extension_path   => '/usr/lib/x86_64-linux-gnu/hhvm/extensions/current',
            dynamic_extensions       => [ 'luasandbox.so', 'tidy.so', 'wikidiff2.so' ],
            enable_obj_destruct_call => true,
            enable_zend_compat       => true,
            pid_file                 => '',  # PID file managed by start-stop-daemon(8)
            resource_limit           => { core_file_size => to_bytes('8 Gb') },
            timeouts_use_wall_time   => true,
            jit_pseudomain           => false,  # Don't JIT file scope. See commit message of e8c4175221.
            log                      => {
                header             => true,
                use_syslog         => true,
                level              => 'Error',
                native_stack_trace => true,
            },
            mysql                    => {
                typed_results        => false,
                slow_query_threshold => to_milliseconds('10s'),
            },
            debug                    => {
                core_dump_report_directory => '/var/log/hhvm',
            },
            server                   => {
                light_process_count       => 5,
                light_process_file_prefix => '/var/tmp/hhvm',
                apc                      => {
                    expire_on_sets     => true,  # Purge on expiration
                    ttl_limit          => to_seconds('2 days'),
                },
            },
            hack                     => {
                lang => {
                    iconv_ignore_correct => true,
                },
            },
        },
    }


    $fcgi_defaults = {
        memory_limit       => '500M',
        max_execution_time => 60,
        hhvm         => {
            jit               => true,
            jit_a_size        => $a_size,
            jit_a_cold_size   => $a_cold_size,
            jit_a_frozen_size => $a_frozen_size,
            perf_pid_map      => true,  # See <http://www.brendangregg.com/perf.html#JIT%20Symbols>
            repo              => { central => { path => '/var/cache/hhvm/fcgi.hhbc.sq3' } },
            admin_server      => { port => 9001 },
            server            => {
                port                   => 9000,
                type                   => 'fastcgi',
                gzip_compression_level => 0,
                stat_cache             => true,
                dns_cache              => {
                    enable => true,
                    ttl    => to_seconds('5 minutes'),
                },
            },
        },
    }

    $cli_defaults = {
        hhvm => {
            jit          => false,
            perf_pid_map => false,
            repo         => {
                central => { path => '/var/cache/hhvm/cli.hhbc.sq3' },
                local   => { mode => '--' },
            }
        }
    }

    $cli_hiera    = hiera_hash('hhvm::extra::cli', {})
    $fcgi_hiera   = hiera_hash('hhvm::extra::fcgi', {})


    ## Config files

    file { '/etc/hhvm/php.ini':
        content => php_ini($common_defaults, $cli_defaults, $cli_settings, $cli_hiera),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }

    file { '/etc/hhvm/fcgi.ini':
        content => php_ini($common_defaults, $fcgi_defaults, $fcgi_settings, $fcgi_hiera),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['hhvm'],
    }

    file { '/var/cache/hhvm/cli.hhbc.sq3':
        ensure => present,
        mode   => '0644',
        owner  => $user,
        group  => $group,
        before => File['/etc/hhvm/php.ini'],
    }

    file { '/var/cache/hhvm/fcgi.hhbc.sq3':
        ensure => present,
        mode   => '0644',
        owner  => $user,
        group  => $group,
        before => File['/etc/hhvm/fcgi.ini'],
    }


    ## Service

    file { '/etc/default/hhvm':
        content => template('hhvm/hhvm.default.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['hhvm'],
    }

    file { '/etc/init/hhvm.conf':
        source => 'puppet:///modules/hhvm/hhvm.conf',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        notify => Service['hhvm'],
    }

    service { 'hhvm':
        ensure    => 'running',
        provider  => 'upstart',
        subscribe => Package['hhvm', 'hhvm-luasandbox', 'hhvm-wikidiff2'],
    }

    file { '/etc/hhvm':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }


    ## Run-time data and logging

    rsyslog::conf { 'hhvm':
        source   => 'puppet:///modules/hhvm/hhvm.rsyslog.conf',
        priority => 20,
        require  => File['/etc/logrotate.d/hhvm'],
        before   => Service['hhvm'],
    }

    file { '/etc/logrotate.d/hhvm':
        source  => 'puppet:///modules/hhvm/hhvm.logrotate',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => File['/var/log/hhvm'],
        before  => Service['hhvm'],
    }

    file { '/var/log/hhvm':
        ensure => directory,
        owner  => 'syslog',
        group  => $group,
        mode   => '0775',
        before => Service['hhvm'],
    }

    file { [ '/run/hhvm', '/var/cache/hhvm', '/tmp/heaps' ]:
        ensure => directory,
        owner  => $user,
        group  => $group,
        mode   => '0755',
        before => Service['hhvm'],
    }


    # Prune stale symbol translation maps from /tmp. These files are
    # generated by HHVM to supply `perf` with language-level context.

    cron { 'tidy_perf_maps':
        command => '/usr/bin/find /tmp -name "perf-*" -not -cnewer /run/hhvm/hhvm.pid -delete > /dev/null 2>&1',
        hour    => fqdn_rand(23, 'tidy_perf_maps'),
        minute  => 0,
    }
}
