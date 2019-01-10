# == Class: hhvm
#
# This module provisions HHVM -- an open-source, high-performance
# virtual machine for PHP.
#
# The layout of configuration files in /etc/hhvm is as follows:
#
#   /etc/hhvm
#   |__ php.ini      # Settings for CLI mode
#   |__ server.ini     # Settings for FastCGI mode
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
# [*service_params*]
#  A hash of parameters passed to base::service_unit and hence to the Puppet
#  service resource.
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
    $user           = 'www-data',
    $group          = 'www-data',
    $service_params = {},
    $fcgi_settings  = {},
    $cli_settings   = {},
    $base_jit_size  = to_bytes('400 Mb'),
    $log_dir        = '/var/log/hhvm',
    $tmp_dir        = '/var/tmp/hhvm',
    $cache_dir      = '/var/cache/hhvm',
    $malloc_arenas  = undef,
    ) {


    $ext_pkgs = [ 'hhvm-luasandbox', 'hhvm-tidy', 'hhvm-wikidiff2' ]

    package { 'hhvm':
        ensure => present,
    }

    package { $ext_pkgs:
        ensure => present,
    }

    # Helpful for debugging luasandbox crashes
    require_package('liblua5.1-0-dbg')

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


    # HHVM specific
    $dynamic_extensions = [ 'luasandbox.so', 'tidy.so', 'wikidiff2.so' ]

    $common_defaults = {
        date         => { timezone => 'UTC' },
        include_path => '.:/usr/share/php',

        pcre         => {
            backtrack_limit => 5000000, # T201184
        },

        hhvm         => {
            dynamic_extension_path   => '/usr/lib/x86_64-linux-gnu/hhvm/extensions/20150212',
            dynamic_extensions       => $dynamic_extensions,
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
                core_dump_report_directory => $log_dir,
            },
            server                   => {
                light_process_count       => 5,
                light_process_file_prefix => $tmp_dir,
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
            repo              => {
                central => {
                    path => "${cache_dir}/fcgi.hhbc.sq3",
                },
            },
            admin_server      => { port => 9001 },
            server            => {
                port                   => 9000,
                'type'                 => 'fastcgi',
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
                central => { path => "${cache_dir}/cli.hhbc.sq3" },
                local   => { mode => '--' },
            },
        },
    }

    ## Config files

    file { '/etc/hhvm/php.ini':
        content => php_ini($common_defaults, $cli_defaults, $cli_settings),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }

    file { '/etc/hhvm/server.ini':
        content => php_ini($common_defaults, $fcgi_defaults, $fcgi_settings),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['hhvm'],
    }

    file { "${cache_dir}/cli.hhbc.sq3":
        ensure => present,
        mode   => '0644',
        owner  => $user,
        group  => $group,
        before => File['/etc/hhvm/php.ini'],
    }

    file { "${cache_dir}/fcgi.hhbc.sq3":
        ensure => present,
        mode   => '0644',
        owner  => $user,
        group  => $group,
        before => File['/etc/hhvm/server.ini'],
    }


    ## Service

    file { '/etc/default/hhvm':
        content => template("hhvm/hhvm.default.${::initsystem}.erb"),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['hhvm'],
    }

    base::service_unit { 'hhvm':
        ensure           => present,
        systemd_override => init_template('hhvm', 'systemd_override'),
        upstart          => upstart_template('hhvm'),
        refresh          => false,
        service_params   => $service_params,
        subscribe        => Package[$ext_pkgs],
    }

    if $::initsystem == 'systemd' {
        # Post-stop script to collect stacktraces
        file { '/usr/local/bin/check-hhvm-stacktraces':
            ensure => present,
            mode   => '0550',
            owner  => $user,
            group  => $group,
            source => 'puppet:///modules/hhvm/check-hhvm-stacktraces.sh',
            before => Base::Service_unit['hhvm'],
        }
    }

    file { '/etc/hhvm':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    file {  '/usr/local/bin/hhvm-needs-restart':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/hhvm/hhvm-needs-restart.sh',
    }

    ## Run-time data and logging

    rsyslog::conf { 'hhvm':
        content  => template('hhvm/hhvm.rsyslog.conf.erb'),
        priority => 20,
        require  => File['/etc/logrotate.d/hhvm'],
        before   => Service['hhvm'],
    }

    file { '/etc/logrotate.d/hhvm':
        content => template('hhvm/hhvm.logrotate.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => File[$log_dir],
        before  => Service['hhvm'],
    }

    file { $log_dir:
        ensure => directory,
        owner  => 'root',
        group  => $group,
        mode   => '0775',
        before => Service['hhvm'],
    }

    file { [ '/run/hhvm', $cache_dir, '/tmp/heaps' ]:
        ensure => directory,
        owner  => $user,
        group  => $group,
        mode   => '0755',
        before => Service['hhvm'],
    }


    # Prune stale symbol translation maps from /tmp. These files are
    # generated by HHVM to supply `perf` with language-level context.
    $procfile = $::initsystem ? {
        'systemd' => '/sys/fs/cgroup/systemd/system.slice/hhvm.service/cgroup.procs',
        default   => '/run/hhvm/hhvm.pid',
    }
    cron { 'tidy_perf_maps':
        command => "/usr/bin/find /tmp -name \"perf-*\" -not -cnewer ${procfile} -delete > /dev/null 2>&1",
        hour    => fqdn_rand(24, 'tidy_perf_maps'),
        minute  => 0,
    }
}
