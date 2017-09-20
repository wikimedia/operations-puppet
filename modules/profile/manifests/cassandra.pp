# == Class profile::cassandra
#
class profile::cassandra(
    $all_instances = hiera('profile::cassandra::instances'),
    $rack = hiera('profile::cassandra::rack'),
    $cassandra_settings = hiera('profile::cassandra::settings'),
    $metrics_blacklist = hiera('profile::cassandra::metrics_blacklist'),
    $metrics_whitelist = hiera('profile::cassandra::metrics_whitelist'),
    $graphite_host = hiera('graphite_host'),
    $prometheus_nodes = hiera('prometheus_nodes'),
    $allow_analytics = hiera('profile::cassandra::allow_analytics')
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


    class { '::cassandra::metrics':
        graphite_host => $graphite_host,
        whitelist     => $metrics_whitelist,
        blacklist     => $metrics_blacklist,
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
            instances        => $instances,
            tls_cluster_name => $tls_cluster_name,
        }
    } else {
        $default_instances = {
            'default' => {
                'listen_address' => $::cassandra::listen_address,
        }}
        ::cassandra::instance::monitoring{ 'default':
            instances        => $default_instances,
            tls_cluster_name => $tls_cluster_name,
        }
    }

    # temporary collector, T78514
    diamond::collector { 'CassandraCollector':
        ensure => absent,
    }

    system::role { 'cassandra':
        description => 'Cassandra server',
    }

    $cassandra_hosts_ferm = join($ferm_seeds, ' ')
    $prometheus_nodes_ferm = join($prometheus_nodes, ' ')

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
    # XXX TEMP XXX
    # RESTBase is currently migrating from Cass 2 to Cass 3 by gradually
    # switching use-cases from one to the other, which means that there
    # are currently two Cassandra clusters being used by RESTBase. However,
    # we are running RESTBase only on nodes with Cassandra 2. In this hack
    # we are allowing the RESTBase hosts to talk to Cassandra 3.x nodes.
    $extra_cql_hosts = hiera('profile::cassandra::extra_cql_hosts', [])
    unless empty($extra_cql_hosts) {
        $extra_cql_ferm = join($extra_cql_hosts, ' ')
        $srange_cql = "${cassandra_hosts_ferm} ${extra_cql_ferm}"
    } else {
        $srange_cql = $cassandra_hosts_ferm
    }
    # Note: all of the $srange_cql instances below need to be replaced back to
    # $cassandra_hosts_ferm once this hack is no longer needed
    # XXX END TEMP XXX
    # Cassandra CQL query interface
    ferm::service { 'cassandra-cql':
        proto  => 'tcp',
        port   => '9042',
        srange => "@resolve((${srange_cql}))",
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
            srange => "(@resolve((${srange_cql})) ${analytics_networks})",
        }

    }

}
