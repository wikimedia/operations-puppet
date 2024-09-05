# SPDX-License-Identifier: Apache-2.0
# == Class profile::cassandra
#
class profile::cassandra(
    Hash $all_instances                       = lookup('profile::cassandra::instances'),
    String $rack                              = lookup('profile::cassandra::rack'),
    Hash $cassandra_settings                  = lookup('profile::cassandra::settings'),
    Array[Stdlib::IP::Address] $client_ips    = lookup('profile::cassandra::client_ips', {'default_value' => []}),
    Boolean $allow_analytics                  = lookup('profile::cassandra::allow_analytics'),
    Boolean $monitor_enabled                  = lookup('profile::cassandra::monitor_enabled', {'default_value' => true}),
    Boolean $auto_apply_grants                = lookup('profile::cassandra::auto_apply_grants', {'default_value' => false}),
    Hash[String, String] $cassandra_passwords = lookup('profile::cassandra::user_credentials', {'default_value' => {}}),
    Integer $monitor_tls_port                 = lookup('profile::cassandra::monitor_tls_port', {'default_value' => 7001}),
    Optional[String] $tls_keystore_password = lookup('profile::cassandra::tls_keystore_password', {'default_value' => undef}),
){

    contain ::profile::java
    $instances = $all_instances[$::fqdn]
    # We get the cassandra seeds from $all_instances, with a template hack
    # This is preferred over a very specialized parser function.
    $all_seeds = split(template('profile/cassandra/seeds.erb'), '\|')
    $seeds = split($all_seeds[0], ',')
    $ferm_seeds = split($all_seeds[1], ',')

    $base_settings = {
        'instances'             => $instances,
        'rack'                  => $rack,
        'seeds'                 => $seeds,
        'logstash_host'         => 'localhost',
        'cassandra_passwords'   => $cassandra_passwords,
        'java_package'          => $profile::java::default_package_name,
        'auto_apply_grants'     => $auto_apply_grants,
        'tls_keystore_password' => $tls_keystore_password,
    }
    $cassandra_real_settings = merge($base_settings, $cassandra_settings)

    create_resources('class', {'::cassandra' => $cassandra_real_settings})

    # rsyslog forwards json messages sent to localhost along to logstash via kafka
    if $cassandra_real_settings['logstash_host'] == 'localhost' {
        class { '::profile::rsyslog::udp_json_logback_compat': }
    }

    class { '::cassandra::logging': }

    class { '::cassandra::sysctl':
        # Queue page flushes at 24MB intervals
        vm_dirty_background_bytes => 25165824,
    }

    if $instances {
        $instance_names = keys($instances)
        ::cassandra::instance::monitoring{ $instance_names:
            monitor_enabled  => $monitor_enabled,
            instances        => $instances,
            tls_cluster_name => $cassandra_settings['tls_cluster_name'],
            tls_port         => $monitor_tls_port,
            tls_use_pki      => $cassandra_settings['tls_use_pki'],
        }
    } else {
        $default_instances = {
            'default' => {
                'listen_address' => $::cassandra::listen_address,
        }}
        ::cassandra::instance::monitoring{ 'default':
            monitor_enabled  => $monitor_enabled,
            instances        => $default_instances,
            tls_cluster_name => $cassandra_settings['tls_cluster_name'],
            tls_port         => $monitor_tls_port,
        }
    }

    $cassandra_hosts_ferm = join($ferm_seeds, ' ')
    $client_ips_ferm = join($client_ips, ' ')

    # Cassandra intra-node messaging
    ferm::service { 'cassandra-intra-node':
        proto  => 'tcp',
        port   => 7000,
        srange => "@resolve((${cassandra_hosts_ferm}))",
    }

    if $cassandra_settings['tls_cluster_name'] {
        # Cassandra intra-node SSL messaging
        ferm::service { 'cassandra-intra-node-ssl':
            proto  => 'tcp',
            port   => 7001,
            srange => "@resolve((${cassandra_hosts_ferm}))",
        }
    }

    # Cassandra JMX/RMI
    ferm::service { 'cassandra-jmx-rmi':
        proto      => 'tcp',
        # hardcoded limit of 4 instances per host
        port_range => [7199, 7202],
        srange     => "@resolve((${cassandra_hosts_ferm}))",
    }

    # Cassandra CQL query interface
    # Note: $client_ips is presumed to be IPs and not be resolved
    ferm::service { 'cassandra-cql':
        proto  => 'tcp',
        port   => 9042,
        srange => "(@resolve((${cassandra_hosts_ferm})) ${client_ips_ferm})",
    }
    if $allow_analytics {
        include ::network::constants
        $analytics_networks = join($network::constants::analytics_networks, ' ')
        ferm::service { 'cassandra-analytics-cql':
            proto  => 'tcp',
            port   => 9042,
            srange => "(@resolve((${cassandra_hosts_ferm})) ${analytics_networks})",
        }

    }

}
