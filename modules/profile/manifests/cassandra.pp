# == Class profile::cassandra
#
class profile::cassandra(
    $all_instances = hiera('profile::cassandra::instances'),
    $rack = hiera('profile::cassandra::rack'),
    $cassandra_settings = hiera('profile::cassandra::settings'),
    $graphite_host = hiera('graphite_host'),
    $prometheus_nodes = hiera('prometheus_nodes'),
    Array[Stdlib::IP::Address] $client_ips = hiera('profile::cassandra::client_ips', []),
    $allow_analytics = hiera('profile::cassandra::allow_analytics'),
    $metrics_blacklist = hiera('profile::cassandra::metrics_blacklist', undef),
    $metrics_whitelist = hiera('profile::cassandra::metrics_whitelist', undef),
    $monitor_enabled = hiera('profile::cassandra::monitor_enabled', true),
    $disable_graphite_metrics = hiera('profile::cassandra::disable_graphite_metrics', false),
) {
    include ::passwords::cassandra
    $instances = $all_instances[$::fqdn]
    # We get the cassandra seeds from $all_instances, with a template hack
    # This is preferred over a very specialized parser function.
    $all_seeds = split(template('profile/cassandra/seeds.erb'), '\|')
    $seeds = split($all_seeds[0], ',')
    $ferm_seeds = split($all_seeds[1], ',')

    $base_settings = {
        'instances' => $instances,
        'rack'      => $rack,
        'seeds'     => $seeds,
    }
    $cassandra_real_settings = merge($base_settings, $cassandra_settings)

    create_resources('class', {'::cassandra' => $cassandra_real_settings})

    # Selectively disable the cassandra metrics collector - T186567
    $ensure_cassandra_metrics = $disable_graphite_metrics ? {
        true    => absent,
        default => present,
    }

    class { '::cassandra::metrics':
        graphite_host => $graphite_host,
        whitelist     => $metrics_whitelist,
        blacklist     => $metrics_blacklist,
        ensure        => $ensure_cassandra_metrics,
    }

    class { '::cassandra::logging': }
    class { '::cassandra::twcs': }

    class { '::cassandra::sysctl':
        # Queue page flushes at 24MB intervals
        vm_dirty_background_bytes => 25165824,
    }

    if $cassandra_settings['tls_cluster_name'] {
        $tls_cluster_name = $cassandra_settings['tls_cluster_name']
    } else {
        $tls_cluster_name = ''
    }
    if $instances {
        $instance_names = keys($instances)
        ::cassandra::instance::monitoring{ $instance_names:
            monitor_enabled  => $monitor_enabled,
            instances        => $instances,
            tls_cluster_name => $tls_cluster_name,
        }
    } else {
        $default_instances = {
            'default' => {
                'listen_address' => $::cassandra::listen_address,
        }}
        ::cassandra::instance::monitoring{ 'default':
            monitor_enabled  => $monitor_enabled,
            instances        => $default_instances,
            tls_cluster_name => $tls_cluster_name,
        }
    }

    system::role { 'cassandra':
        description => 'Cassandra server',
    }

    $cassandra_hosts_ferm = join($ferm_seeds, ' ')
    $prometheus_nodes_ferm = join($prometheus_nodes, ' ')
    $client_ips_ferm = join($client_ips, ' ')

    # Cassandra intra-node messaging
    ferm::service { 'cassandra-intra-node':
        proto  => 'tcp',
        port   => '7000',
        srange => "@resolve((${cassandra_hosts_ferm}))",
    }

    if $cassandra_settings['tls_cluster_name'] {
        # Cassandra intra-node SSL messaging
        ferm::service { 'cassandra-intra-node-ssl':
            proto  => 'tcp',
            port   => '7001',
            srange => "@resolve((${cassandra_hosts_ferm}))",
        }
    }

    # Cassandra JMX/RMI
    ferm::service { 'cassandra-jmx-rmi':
        proto  => 'tcp',
        # hardcoded limit of 4 instances per host
        port   => '7199:7202',
        srange => "@resolve((${cassandra_hosts_ferm}))",
    }

    # Cassandra CQL query interface
    # Note: $client_ips is presumed to be IPs and not be resolved
    ferm::service { 'cassandra-cql':
        proto  => 'tcp',
        port   => '9042',
        srange => "(@resolve((${cassandra_hosts_ferm})) ${client_ips_ferm})",
    }
    # Prometheus jmx_exporter for Cassandra
    ferm::service { 'cassandra-jmx_exporter':
        proto  => 'tcp',
        port   => '7800',
        srange => "@resolve((${prometheus_nodes_ferm}))",
    }
    if $allow_analytics {
        include ::network::constants
        $analytics_networks = join($network::constants::analytics_networks, ' ')
        ferm::service { 'cassandra-analytics-cql':
            proto  => 'tcp',
            port   => '9042',
            srange => "(@resolve((${cassandra_hosts_ferm})) ${analytics_networks})",
        }

    }

}
