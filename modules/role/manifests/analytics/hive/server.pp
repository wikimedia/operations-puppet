# == Class role::analytics::hive::server
# Sets up Hive Server2 and MySQL backed Hive Metastore.
#
class role::analytics::hive::server inherits role::analytics::hive::client {
    if (!defined(Package['mysql-server'])) {
        package { 'mysql-server':
            ensure => 'installed',
        }
    }

    # Make sure mysql-server is installed before
    # MySQL Hive Metastore database class is applied.
    # Package['mysql-server'] -> Class['cdh::hive::metastore::mysql']

    # TODO: Set these better once hive is on its own server.
    # See: https://phabricator.wikimedia.org/T110090
    # http://www.cloudera.com/content/www/en-us/documentation/enterprise/latest/topics/cdh_ig_hive_install.html#concept_alp_4kl_3q_unique_1
    # TODO: Use hiera.
    $server_heapsize = $::realm ? {
        'production' => 1024,
        default      => undef,
    }
    $metastore_heapsize = $::realm ? {
        'production' => 256,
        default      => undef,
    }
    # # Setup Hive server and Metastore
    # class { 'cdh::hive::master':
    #     server_heapsize    => $server_heapsize,
    #     metastore_heapsize => $metastore_heapsize,
    # }

    class { 'cdh::hive::server':
        heapsize => $server_heapsize,
    }
    class { 'cdh::hive::metastore':
        heapsize => $metastore_heapsize,
    }

    ferm::service{ 'hive_server':
        proto  => 'tcp',
        port   => '10000',
        srange => '$INTERNAL',
    }

    ferm::service{ 'hive_metastore':
        proto  => 'tcp',
        port   => '9083',
        srange => '$INTERNAL',
    }
}
