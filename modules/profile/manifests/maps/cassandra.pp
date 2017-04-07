class profile::maps::cassandra {
    $cassandra_hosts = hiera('profile::maps::cassandra::seeds')
    $cluster_name = hiera('cluster')
    $graphite_host = hiera('profile::maps::cassandra::graphite_host')
    $dc = hiera('profile::maps::cassandra::dc')

    # Cassandra grants
    $cassandra_kartotherian_pass = hiera('profile::maps::cassandra::kartotherian_pass')
    $cassandra_tilerator_pass = hiera('profile::maps::cassandra::tilerator_pass')
    $cassandra_tileratorui_pass = hiera('profile::maps::cassandra::tileratorui_pass')

    system::role { 'profile::maps::cassandra':
        ensure      => 'present',
        description => 'Maps Cassandra server',
    }

    class { '::cassandra':
        cluster_name           => $cluster_name,
        data_directory_base    => '/srv/cassandra',
        data_file_directories  => [ '/srv/cassandra/data' ],
        commitlog_directory    => '/srv/cassandra/commitlog',
        saved_caches_directory => '/srv/cassandra/saved_caches',
        graphite_host          => $graphite_host,
        dc                     => $dc,
    }
    include ::cassandra::metrics
    include ::cassandra::logging

    file { '/usr/local/bin/maps-grants.cql':
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        content => template('profile/maps/grants.cql.erb'),
    }

    ::cassandra::instance::monitoring{ 'default':
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