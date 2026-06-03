# @summary Redis with Sentinel and Keepalived for high availability
class profile::toolforge::redis_sentinel (
    Stdlib::Fqdn        $redis_primary         = lookup('profile::toolforge::redis_sentinel::primary'),
    Array[Stdlib::Fqdn] $redis_hosts           = lookup('profile::toolforge::redis_sentinel::redis_hosts',           {default_value => []}),
    String              $maxmemory             = lookup('profile::toolforge::redis_sentinel::maxmemory',             {default_value => '12GB'}),
    String              $secret_command_prefix = lookup('profile::toolforge::redis_sentinel::secret_command_prefix', {default_value => 'notasecret'}),
    Array[Stdlib::Host] $keepalived_vips       = lookup('profile::toolforge::redis_sentinel::keepalived_vips',       {default_value => []}),
    String              $keepalived_password   = lookup('profile::toolforge::redis_sentinel::keepalived_password',   {default_value => 'notarealpassword'}),
) {
    $redis_sentinel_own_address = $::facts['networking']['ip']
    $redis_primary_address = ipresolve($redis_primary)

    # Security by obscurity! https://words.yuvi.in/attempting-to-secure-redis-in-a-multi-tenant-environment/
    # These commands are dangerous and should not be used by normal users
    $secret_commands = [
        'CLIENT',
        'CONFIG',
        'DEBUG',
        'FLUSHALL',
        'FLUSHDB',
        'KEYS',
        'MONITOR',
        'RANDOMKEY',
        'REPLICAOF',
        'SCAN',
        'SHUTDOWN',
        'SLAVEOF',
    ]

    # ... but since Sentinel needs some of them to perform failovers, let's prefix
    # them with a secret string so they're practically unusable
    # TODO: figure out which ones are needed and which ones can be truly removed
    $mapped_secret_commands = $secret_commands.reduce({}) |$cumulate, $secret_command| {
        merge($cumulate, {"${secret_command}" => "${secret_command_prefix}${secret_command}"})
    }

    ensure_packages('redis-sentinel')

    service { 'redis-sentinel':
        ensure  => stopped,
        enable  => false,
        require => Package['redis-sentinel'],
    }

    # Set up a non-default instance so we have total control over the creation of its config
    # since redis-sentinel stores some information in the config, we can't just overwrite
    # it every time, but we want to set the initial values
    file { '/etc/redis/sentinel-toolforge.conf':
        content   => template('profile/toolforge/redis/sentinel.conf.erb'),
        owner     => 'redis',
        group     => 'redis',
        mode      => '0640',
        require   => Package['redis-sentinel'],
        notify    => Service['redis-sentinel@toolforge'],
        replace   => false,
        show_diff => false,
    }

    service { 'redis-sentinel@toolforge':
        ensure  => running,
        enable  => true,
        require => File['/etc/redis/sentinel-toolforge.conf'],
    }

    if $redis_primary != $::fqdn {
        $slaveof = "${redis_primary_address} 6379"
    } else {
        $slaveof = undef
    }

    redis::instance { '6379':
        # prevent puppet and sentinel fighting each other (T309014)
        # TODO: figure out if we can have a more elegant solution
        allow_config_writes => true,
        settings            => {
            client_output_buffer_limit  => 'slave 512mb 200mb 60',
            dbfilename                  => "${::hostname}-6379.rdb",
            dir                         => '/srv/redis',
            maxmemory                   => $maxmemory,
            maxmemory_policy            => 'allkeys-lru',
            maxmemory_samples           => 5,
            save                        => '300 100',
            slave_read_only             => true,
            stop_writes_on_bgsave_error => false,
            slave_priority              => fqdn_rand(99) + 1,
            slaveof                     => $slaveof,
            bind                        => '* -::*',
            protected-mode              => 'no',
            rename_command              => $mapped_secret_commands,
            timeout                     => 600,
        },
    }

    # Monitoring!
    prometheus::redis_exporter { '6379':
        arguments => '-set-client-name=false',
    }

    # Allow users to connect
    firewall::service { 'toolforge-redis-access':
        proto => 'tcp',
        port  => 6379,
    }

    # Sentinels need to talk to each other
    firewall::service { 'toolforge-redis-sentinel-internal':
        proto  => 'tcp',
        port   => 26379,
        srange => $redis_hosts,
    }

    # and keepalived too
    ferm::rule { 'toolforge-redis-keepalived-vrrp':
        rule => "proto vrrp saddr (@resolve((${redis_hosts.join(' ')}))) ACCEPT;",
    }

    nftables::service { 'toolforge-redis-keepalived-vrrp':
        proto   => 'vrrp',
        src_ips => $redis_hosts.wmflib::hosts2ips(),
    }

    # Script that keepalived users to check if this instance should have all the traffic
    file { '/usr/local/bin/wmcs-check-redis-master':
        source => 'puppet:///modules/profile/toolforge/redis/wmcs-check-redis-master.sh',
        owner  => 'root',
        group  => 'redis',
        mode   => '0550',
    }

    class { 'keepalived::failover':
        virtual_router_id => 30,
        auth_pass         => $keepalived_password,
        peers             => $redis_hosts.delete($facts['networking']['fqdn']),
        vips              => $keepalived_vips.wmflib::hosts2ips(),
        track_script      => '/usr/local/bin/wmcs-check-redis-master',
        track_script_user => 'redis',
    }
}
