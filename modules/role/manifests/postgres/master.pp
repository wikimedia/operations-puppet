class role::postgres::master {
    include role::postgres::common
    include ::postgresql::postgis
    include ::passwords::postgres
    include ::base::firewall
    include ::profile::prometheus::postgres_exporter

    class { 'postgresql::master':
        includes => 'tuning.conf',
        root_dir => $role::postgres::common::root_dir,
    }

    system::role { 'postgres::master':
        ensure      => 'present',
        description => 'Postgres db master',
    }

    $postgres_slave = hiera('role::postgres::master::slave', undef)
    if $postgres_slave {
        $postgres_slave_v4 = ipresolve($postgres_slave, 4)
        if $postgres_slave_v4 {
            postgresql::user { "replication@${::postgres_slave}-v4":
                ensure   => 'present',
                user     => 'replication',
                password => $passwords::postgres::replication_pass,
                cidr     => "${::postgres_slave_v4}/32",
                type     => 'host',
                method   => 'md5',
                attrs    => 'REPLICATION',
                database => 'all',
            }
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
