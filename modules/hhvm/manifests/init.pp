# == Class: hhvm
#
# This module provisions HHVM -- an open-source, high-performance
# virtual machine for PHP.
#
# The layout of configuration files in /etc/hhvm is as follows:
#
#   /etc/hhvm
#   ├── php.ini      # Settings for CLI mode
#   └── fcgi.ini     # Settings for FastCGI mode
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
#   ├── error.log
#   └── stacktrace.NNN.log.YYYYMMDD, ...
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
) {
    requires_ubuntu('>= trusty')


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
    # A ratio of 1 : 0.33 : 1 for a : a_cold : a_frozen is good general
    # guidance.

    $base_jit_size = to_bytes('100 Mb')
    $a_size        = $base_jit_size
    $a_cold_size   = 0.33 * $base_jit_size
    $a_frozen_size = $base_jit_size


    $common_defaults = {
        date => { timezone => 'UTC' },
        hhvm => {
            dynamic_extension_path   => '/usr/lib/x86_64-linux-gnu/hhvm/extensions/current',
            dynamic_extensions       => [ 'fss.so', 'luasandbox.so', 'wikidiff2.so' ],
            enable_obj_destruct_call => true,
            enable_zend_compat       => true,
            include_path             => '.:/usr/share/php',
            perf_pid_map             => false,
            pid_file                 => '',  # PID file managed by start-stop-daemon(8)
            resource_limit           => { core_file_size => to_bytes('8 Gb') },
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
        },
    }


    $fcgi_defaults = {
        memory_limit => '300M',
        hhvm         => {
            jit               => true,
            jit_a_size        => $a_size,
            jit_a_cold_size   => $a_cold_size,
            jit_a_frozen_size => $a_frozen_size,
            repo              => { central => { path => '/run/hhvm/cache/fcgi.hhbc.sq3' } },
            admin_server      => { port => 9001 },
            server            => {
                port                   => 9000,
                type                   => 'fastcgi',
                gzip_compression_level => 0,
                graceful_shutdown_wait => 5,
            },
        },
    }

    $cli_defaults = {
        hhvm => {
            jit  => false,
            repo => {
                central => { path => '/run/hhvm/cache/cli.hhbc.sq3' },
                local   => { mode => '--' },
            }
        }
    }


    ## Config files

    file { '/etc/hhvm/php.ini':
        content => php_ini($common_defaults, $cli_defaults, $cli_settings),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }

    file { '/etc/hhvm/fcgi.ini':
        content => php_ini($common_defaults, $fcgi_defaults, $fcgi_settings),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['hhvm'],
    }


    ## Packages

    package { [ 'hhvm', 'hhvm-dbg' ]:
        ensure => present,
        before => Service['hhvm'],
    }

    package { [ 'hhvm-fss', 'hhvm-luasandbox', 'hhvm-wikidiff2' ]:
        ensure => present,
        before => Service['hhvm'],
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
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['hhvm'],
    }

    service { 'hhvm':
        ensure   => 'running',
        provider => 'upstart',
    }

    file { '/etc/hhvm':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    file { '/usr/local/sbin/hhvm-dump-debug':
        source => 'puppet:///modules/hhvm/hhvm-dump-debug',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        before => Service['hhvm'],
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

    file { [ '/run/hhvm', '/run/hhvm/cache' ]:
        ensure => directory,
        owner  => $user,
        group  => $group,
        mode   => '0755',
        before => Service['hhvm'],
    }
}
