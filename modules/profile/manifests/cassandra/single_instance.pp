class profile::cassandra::single_instance(
  Stdlib::Host        $graphite_host        = lookup('graphite_host'),
  String              $cluster_name         = lookup('profile::cassandra::single_instance::cluster'),
  Array[Stdlib::Host] $cassandra_hosts      = lookup('profile::cassandra::single_instance::seeds'),
  String              $dc                   = lookup('profile::cassandra::single_instance::dc'),
  String              $super_pass           = lookup('profile::cassandra::single_instance::super_pass'),
  Optional[String]    $target_version       = lookup('profile::cassandra::single_instance::target_version', {'default_value' => undef}),
  Optional[String]    $rack                 = lookup('profile::cassandra::single_instance::rack', {'default_value' => undef}),
) {
  # localhost udp endpoint for logging pipeline
  class { 'profile::rsyslog::udp_json_logback_compat': }
  contain ::profile::java

  class { 'cassandra':
    cluster_name            => $cluster_name,
    seeds                   => $cassandra_hosts,
    dc                      => $dc,
    rack                    => $rack,
    logstash_host           => 'localhost',
    java_package            => $profile::java::default_package_name,
    target_version          => $target_version,
    default_instance_params => {
      data_directory_base    => '/srv/cassandra',
      commitlog_directory    => '/srv/cassandra/commitlog',
      saved_caches_directory => '/srv/cassandra/saved_caches',
      super_password         => $super_pass
    }
  }
  class {'cassandra::logging': }

  cassandra::instance::monitoring { 'default':
    instances => {
      'default' => {
        'listen_address' => $::cassandra::listen_address,
      }
    },
  }

  $cassandra_hosts_ferm = join($cassandra_hosts, ' ')

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

  # Cassandra Thrift interface, used by cqlsh
  # TODO: Is that really true? Since CQL 3.0 it should not be. Revisit
  ferm::service { 'cassandra-cql-thrift':
    proto  => 'tcp',
    port   => '9160',
    srange => "(${cassandra_hosts_ferm})",
  }

}
