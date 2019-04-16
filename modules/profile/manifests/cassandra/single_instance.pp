class profile::cassandra::single_instance(
  $cassandra_hosts = hiera('profile::cassandra::single_instance::seeds'),
  $cluster_name = hiera('cluster'),
  $prometheus_nodes = hiera('prometheus_nodes'),
  $graphite_host = hiera('profile::cassandra::single_instance::graphite_host'),
  $dc = hiera('profile::cassandra::single_instance::dc'),
  $super_pass = hiera('profile::cassandra::single_instance::super_pass'),
  $jmx_exporter_enabled = hiera('profile::cassandra::single_instance::jmx_exporter_enabled'),
) {

  class { '::cassandra':
    cluster_name            => $cluster_name,
    seeds                   => $cassandra_hosts,
    dc                      => $dc,
    default_instance_params => {
      data_directory_base    => '/srv/cassandra',
      commitlog_directory    => '/srv/cassandra/commitlog',
      saved_caches_directory => '/srv/cassandra/saved_caches',
      super_password         => $super_pass,
      jmx_exporter_enabled   => $jmx_exporter_enabled,
    }
  }
  class { '::cassandra::metrics':
    graphite_host => $graphite_host,
  }
  include ::cassandra::logging

  ::cassandra::instance::monitoring { 'default':
    instances => {
      'default' => {
        'listen_address' => $::cassandra::listen_address,
      }
    },
  }

  $cassandra_hosts_ferm = join($cassandra_hosts, ' ')
  $prometheus_nodes_ferm = join($prometheus_nodes, ' ')

  # Cassandra intra-node messaging
  ferm::service { 'maps-cassandra-intra-node':
    proto  => 'tcp',
    port   => '7000',
    srange => "(${cassandra_hosts_ferm})",
  }

  # Cassandra JMX/RMI
  ferm::service { 'maps-cassandra-jmx-rmi':
    proto  => 'tcp',
    # hardcoded limit of 4 instances per host
    port   => '7199',
    srange => "(${cassandra_hosts_ferm})",
  }

  # Cassandra CQL query interface
  ferm::service { 'cassandra-cql':
    proto  => 'tcp',
    port   => '9042',
    srange => "(${cassandra_hosts_ferm})",
  }

  # Prometheus jmx_exporter for Cassandra
  ferm::service { 'cassandra-jmx_exporter':
      proto  => 'tcp',
      port   => '7800',
      srange => "@resolve((${prometheus_nodes_ferm}))",
  }

  # Cassandra Thrift interface, used by cqlsh
  # TODO: Is that really true? Since CQL 3.0 it should not be. Revisit
  ferm::service { 'cassandra-cql-thrift':
    proto  => 'tcp',
    port   => '9160',
    srange => "(${cassandra_hosts_ferm})",
  }

}