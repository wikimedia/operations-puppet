class role::postgres::slave {
    include role::postgres::common
    include ::postgresql::postgis
    include ::passwords::postgres

    system::role { 'role::postgres::slave':
        ensure      => 'present',
        description => 'Postgres db slave',
    }

    class {'postgresql::slave':
        master_server    => $postgres_master,
        replication_pass => $passwords::postgres::replication_pass,
        includes         => 'tuning.conf',
        datadir          => $role::postgres::common::datadir,
    }

    class { 'postgresql::ganglia':
        pgstats_user => $passwords::postgres::ganglia_user,
        pgstats_pass => $passwords::postgres::ganglia_pass,
    }
}
