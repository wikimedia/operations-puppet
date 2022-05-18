class profile::redis::multidc(
    String $category = lookup('profile::redis::multidc::category'),
    Hash[String, Hash] $all_shards = lookup('redis::shards'),
    String $conftool_prefix = lookup('conftool_prefix'),
    Hash $settings = lookup('profile::redis::multidc::settings'),
    Optional[String] $discovery = lookup('profile::redis::multidc::discovery', {'default_value' => undef}),
    Boolean $aof = lookup('profile::redis::multidc::aof', {default_value => false}),
    Optional[Integer] $version_override = lookup('profile::redis::multidc::version_override'),
) {
    # Hosts where we will install redis multidc are hosts where
    # profile::redis::multidc::version_override is defined

    if (debian::codename::eq('buster') and $version_override) {
        if $version_override {
            apt::package_from_component  { "repository_redis${version_override}":
            component => "component/redis${version_override}",
            packages  => ['redis-server'],
            }
        }
        require ::passwords::redis
        $shards = $all_shards[$category]
        $ip = $facts['ipaddress']
        $instances = $shards[$::site].values.filter |$shard| {
            $shard['host'] == $ip
        }.map |$shard| { String($shard['port']) }.sort
        if $instances.empty {
            fail("No Redis instances found for ${ip}")
        }
        $password = $passwords::redis::main_password
        $uris = $instances.map |$instance| { "localhost:${instance}/${password}" }
        $redis_ports = join($instances, ' ')
        $auth_settings = {
            'masterauth'  => $password,
            'requirepass' => $password,
        }

        class { 'redis::multidc::ipsec':
            shards => $shards
        }
        class { '::ferm::ipsec_allow': }

        file { '/etc/redis/replica/':
            ensure => directory,
            owner  => 'root',
            group  => 'root',
            mode   => '0444',
        }

        # Now the redis instances. We watch etcd every 5 minutes to fix config
        # based on the active datacenter for the chosen discovery label
        class { 'confd':
            interval => 300,
            prefix   => $conftool_prefix,
            srv_dns  => "${::site}.wmnet",
        }

        profile::redis::multidc_instance{ $instances:
            ip        => $ip,
            shards    => $shards,
            discovery => $discovery,
            aof       => $aof,
            settings  => merge($settings, $auth_settings),
        }

        # Add monitoring, using nrpe and not remote checks anymore
        redis::monitoring::nrpe_instance { $instances: }

        ::profile::prometheus::redis_exporter{ $instances:
            password => $password,
        }

        ferm::service { "redis_${category}_role":
            proto   => 'tcp',
            notrack => true,
            port    => inline_template('(<%= @redis_ports %>)'),
        }
    }
}
