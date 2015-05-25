# postgres role classes

class role::postgres::common {
    include standard

    $datadir = '/srv/postgres/9.1/main'

    file { '/etc/postgresql/9.1/main/tuning.conf':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///files/postgres/tuning.conf',
    }

    sysctl::parameters { 'postgres_shmem':
        values => {
            # That is derived after tuning postgresql, deriving automatically is
            # not the safest idea yet.
            'kernel.shmmax' => 8388608000,
        },
    }

    ganglia::plugin::python { 'diskstat': }
}

class role::postgres::master {
    include role::postgres::common
    include ::postgresql::postgis
    include ::passwords::postgres

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

class role::postgres::maps {
    include osm
    postgresql::spatialdb { 'gis': }
    # Import planet.osm
    osm::planet_import { 'gis':
        input_pbf_file => '/srv/labsdb/planet-latest-osm.pbf',
        require        => Postgresql::Spatialdb['gis']
    }
    osm::planet_sync { 'gis':
        period => 'day',
        hour   => '1',
        minute => '17',
    }
}
