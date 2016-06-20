class role::postgres::master {
    include role::postgres::common
    include ::postgresql::postgis
    include ::passwords::postgres
    include base::firewall

    class { 'postgresql::master':
        includes => 'tuning.conf',
        root_dir => $role::postgres::common::root_dir,
    }

    class { 'postgresql::ganglia':
        pgstats_user => $passwords::postgres::ganglia_user,
        pgstats_pass => $passwords::postgres::ganglia_pass,
    }

    system::role { 'role::postgres::master':
        ensure      => 'present',
        description => 'Postgres db master',
    }

    # FIXME - top-scope var without namespace, will break in puppet 2.8
    # lint:ignore:variable_scope
    if $postgres_slave_v4 {
    # lint:endignore
        postgresql::user { "replication@${::postgres_slave}-v4":
            ensure   => 'present',
            user     => 'replication',
            password => $passwords::postgres::replication_pass,
            cidr     => "${::postgres_slave_v4}/32",
            type     => 'host',
            method   => 'md5',
            attrs    => 'REPLICATION',
            database => 'replication',
        }
    }

    # FIXME - top-scope var without namespace, will break in puppet 2.8
    # lint:ignore:variable_scope
    if $postgres_slave_v6 {
    # lint:endignore
        postgresql::user { "replication@${::postgres_slave}-v6":
            ensure   => 'present',
            user     => 'replication',
            password => $passwords::postgres::replication_pass,
            cidr     => "${::postgres_slave_v6}/128",
            type     => 'host',
            method   => 'md5',
            attrs    => 'REPLICATION',
            database => 'replication',
        }
    }
    # An admin user for labs
    postgresql::user { 'labsadmin@labs':
            ensure   => 'present',
            user     => 'labsadmin',
            password => $passwords::postgres::labsadmin_password,
            cidr     => '10.68.16.0/21',
            type     => 'host',
            method   => 'md5',
            attrs    => 'CREATEROLE CREATEDB',
            database => 'template1',
    }
}
