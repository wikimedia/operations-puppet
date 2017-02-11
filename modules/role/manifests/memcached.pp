# vim: noet
#
# filtertags: labs-project-deployment-prep
class role::memcached {
    system::role { 'role::memcached': }

    include ::standard
    include base::mysterious_sysctl
    include ::base::firewall
    include passwords::redis

    $memcached_size = $::realm ? {
        'production' => 89088,
        'labs'       => 3000,
    }

    # There are different package versions available due to a performance test,
    # most of them are deployed/installed manually.
    # More info: T129963
    $version = os_version('debian >= jessie || ubuntu >= trusty') ? {
        true    => hiera('memcached::version', 'present'),
        default => '1.4.15-0wmf1',
    }

    $growth_factor = hiera('memcached::growth_factor', 1.05)
    $extended_options = hiera_array('memcached::extended_options', ['slab_reassign'])

    class { '::memcached':
        size          => $memcached_size,
        port          => 11211,
        version       => $version,
        growth_factor => $growth_factor,
        extra_options => {
            '-o' => join($extended_options, ','),
            '-D' => ':',
        }
    }

    include role::prometheus::memcached_exporter

    # `memkeys` is a `top`-like tool for inspecting memcache key usage in real time.
    # In addition to making it available for interactive use, we configure a cronjob
    # to run once a day and log 20 seconds' worth of memcached usage stats to a CSV
    # file. That way, if there is a spike in memcached usage, we can diff the logs
    # and see which keys are suspect.

    package { 'memkeys':
        ensure => present,
        before => Cron['memkeys'],
    }

    file { '/var/log/memkeys':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        before => Cron['memkeys'],
    }

    file { '/etc/logrotate.d/memkeys':
        source  => 'puppet:///modules/memcached/memkeys.logrotate',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        before  => Cron['memkeys'],
        require => File['/var/log/memkeys'],
    }

    file { '/usr/local/sbin/memkeys-snapshot':
        source => 'puppet:///modules/memcached/memkeys-snapshot',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        before => Cron['memkeys'],
    }

    cron { 'memkeys':
        ensure  => present,
        command => '/usr/local/sbin/memkeys-snapshot',
        user    => 'root',
        hour    => fqdn_rand(23, 'memkeys'),
        minute  => fqdn_rand(59, 'memkeys'),
    }


    $base_settings = {
        bind                        => '0.0.0.0',
        auto_aof_rewrite_min_size   => '512mb',
        client_output_buffer_limit  => 'slave 512mb 200mb 60',
        dir                         => '/srv/redis',
        dbfilename                  => "${::hostname}-6379.rdb",
        masterauth                  => $passwords::redis::main_password,
        maxmemory                   => '500Mb',
        maxmemory_policy            => 'volatile-lru',
        maxmemory_samples           => 5,
        no_appendfsync_on_rewrite   => true,
        requirepass                 => $passwords::redis::main_password,
        save                        => '300 100',
        slave_read_only             => false,
        stop_writes_on_bgsave_error => false,
    }

    $shards = {
        'eqiad' => hiera('mediawiki::redis_servers::eqiad'),
        'codfw' => hiera('mediawiki::redis_servers::codfw')
    }

    if os_version('Debian >= jessie') {
        class { 'redis::multidc::ipsec':
            shards => $shards
        }
    }

    class { 'redis::multidc::instances':
        shards   => $shards,
        settings => $base_settings,
        map      => {
            '6380' => {
                dbfilename => "${::hostname}-6380.rdb",
            }
        }
    }


    # Monitoring

    # Declare monitoring for all redis instances
    redis::monitoring::instance { $::redis::multidc::instances::instances:
        settings => $base_settings,
        map      => $::redis::multidc::instances::replica_map,
    }

    # Firewall rules
    include ::ferm::ipsec_allow

    $redis_ports = join($::redis::multidc::instances::instances, ' ')

    ferm::service { 'redis_memcached_role':
        proto => 'tcp',
        port  => inline_template('(<%= @redis_ports %>)'),
    }

    ferm::service { 'memcached_memcached_role':
        proto => 'tcp',
        port  => '11211',
    }

    rsyslog::conf { 'memkeys':
        content  => template('role/memcached/rsyslog.conf.erb'),
        priority => 40,
    }
}
