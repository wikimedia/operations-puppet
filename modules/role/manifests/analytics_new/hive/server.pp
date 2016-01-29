# == Class role::analytics::hive::server
# Sets up Hive Server2 and MySQL backed Hive Metastore.
#
class role::analytics_new::hive::server {
    system::role { 'role::analytics::hive::server':
        description => 'Hadoop Worker (DataNode & NodeManager)',
    }

    require role::analytics_new::hive::client

    # TODO. This will be removed once the migration off
    # of analytics1027 is complete.
    if $::realm == 'labs' {
        require_package('mysql-server')
    }

    # Setup Hive server and Metastore
    class { 'cdh::hive::master': }

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