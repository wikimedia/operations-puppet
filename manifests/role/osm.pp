# OSM role classes

class role::osm::common {
    include standard

    $datadir = '/srv/postgres'

    file { '/etc/postgresql/9.1/main/tuning.conf':
        ensure => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///files/osm/tuning.conf',
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

class role::osm::master {
    include role::osm::common
    include postgresql::postgis
    include osm::packages
    include passwords::osm

    class { 'postgresql::master':
        includes => 'tuning.conf',
        datadir  => $role::osm::common::datadir,
    }

    class { 'postgresql::ganglia':
        pgstats_user => $passwords::osm::ganglia_user,
        pgstats_pass => $passwords::osm::ganglia_pass,
    }

    system::role { 'role::osm::master':
        ensure      => 'present',
        description => 'openstreetmaps db master',
    }

    # Create the spatialdb
    postgresql::spatialdb { 'gis': }
    # Import planet.osm
    osm::planet_import { 'gis':
        input_pbf_file   => '/srv/labsdb/planet-latest-osm.pbf',
        require          => Postgresql::Spatialdb['gis']
    }
    osm::planet_sync { 'gis':
        period => 'day',
        hour   => '1',
        minute => '17',
    }
    # Add coastlines
    osm::shapefile_import { 'gis-coastlines':
        database         => 'gis',
        input_shape_file => '/srv/labsdb/coastlines-split-4326/lines',
        shape_table      => 'coastlines',
        require          => Postgresql::Spatialdb['gis']
    }
    # Add split land polygons
    osm::shapefile_import { 'gis-land_polygons':
        database         => 'gis',
        input_shape_file => '/srv/labsdb/land-polygons-split-4326/land_polygons',
        shape_table      => 'land_polygons',
        require          => Postgresql::Spatialdb['gis']
    }

    if $osm_slave_v4 {
        postgresql::user { "replication@${::osm_slave}-v4":
            ensure   => 'present',
            user     => 'replication',
            password => $passwords::osm::replication_pass,
            cidr     => "${::osm_slave_v4}/32",
            type     => 'host',
            method   => 'md5',
            attrs    => 'REPLICATION',
            database => 'replication',
        }
    }
    if $osm_slave_v6 {
        postgresql::user { "replication@${::osm_slave}-v6":
            ensure   => 'present',
            user     => 'replication',
            password => $passwords::osm::replication_pass,
            cidr     => "${::osm_slave_v6}/128",
            type     => 'host',
            method   => 'md5',
            attrs    => 'REPLICATION',
            database => 'replication',
        }
    }

    # OSM user
    postgresql::user { 'osm@labs':
            ensure   => 'present',
            user     => 'osm',
            password => $passwords::osm::osm_password,
            cidr     => '10.68.16.0/21',
            type     => 'host',
            method   => 'trust',
            database => 'gis',
    }

    # Specific users and databases
    postgresql::spatialdb { 'u_kolossos': }
    postgresql::user { 'kolossos@labs':
            ensure   => 'present',
            user     => 'kolossos',
            password => $passwords::osm::kolossos_password,
            cidr     => '10.68.16.0/21',
            type     => 'host',
            method   => 'md5',
            database => 'u_kolossos',
    }
    postgresql::spatialdb { 'u_aude': }
    postgresql::user { 'aude@labs':
            ensure   => 'present',
            user     => 'aude',
            password => $passwords::osm::aude_password,
            cidr     => '10.68.16.0/21',
            type     => 'host',
            method   => 'md5',
            database => 'u_aude',
    }
    postgresql::spatialdb { 'wikimaps_atlas': }
    postgresql::user { 'planemad@labs':
            ensure   => 'present',
            user     => 'planemad',
            password => $passwords::osm::planemad_password,
            cidr     => '10.68.16.0/21',
            type     => 'host',
            method   => 'md5',
            database => 'wikimaps_atlas',
    }
}

class role::osm::slave {
    include role::osm::common
    include postgresql::postgis
    include passwords::osm
    # Note: This is here to illustrate the fact that the slave is expected to
    # have the same dbs as the master.
    #postgresql::spatialdb { 'gis': }

    system::role { 'role::osm::slave':
        ensure      => 'present',
        description => 'openstreetmaps db slave',
    }

    class {'postgresql::slave':
        master_server    => $osm_master,
        replication_pass => $passwords::osm::replication_pass,
        includes         => 'tuning.conf',
        datadir          => $role::osm::common::datadir,
    }

    class { 'postgresql::ganglia':
        pgstats_user => $passwords::osm::ganglia_user,
        pgstats_pass => $passwords::osm::ganglia_pass,
    }
}
