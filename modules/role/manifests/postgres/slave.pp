class role::postgres::slave {
    include role::postgres::common
    include ::postgresql::postgis
    include ::passwords::postgres

    system::role { 'postgres::slave':
        ensure      => 'present',
        description => 'Postgres db slave',
    }

    class {'postgresql::slave':
        # FIXME - top-scope var without namespace, will break in puppet 2.8
        # lint:ignore:variable_scope
        master_server    => $postgres_master,
        # lint:endignore
        replication_pass => $passwords::postgres::replication_pass,
        includes         => 'tuning.conf',
        root_dir         => $role::postgres::common::root_dir,
    }
}
