class role::postgres::master {
    include role::postgres::common
    include ::postgresql::postgis
    include ::passwords::postgres
    include base::firewall

    class { 'postgresql::master':
        includes => 'tuning.conf',
        datadir  => $role::postgres::common::datadir,
    }

    class { 'postgresql::ganglia':
        pgstats_user => $passwords::postgres::ganglia_user,
        pgstats_pass => $passwords::postgres::ganglia_pass,
    }

    system::role { 'role::postgres::master':
        ensure      => 'present',
        description => 'Postgres db master',
    }

    if $postgres_slave_v4 {
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
    if $postgres_slave_v6 {
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
