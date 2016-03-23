class role::osm::master {
    include role::osm::common
    include postgresql::postgis
    include osm
    include passwords::osm
    include base::firewall

    class { 'postgresql::master':
        includes => 'tuning.conf',
        datadir  => $role::osm::common::datadir,
    }

    class { 'postgresql::ganglia':
        pgstats_user => $passwords::osm::ganglia_user,
        pgstats_pass => $passwords::osm::ganglia_pass,
    }
    class { 'osm::ganglia':
        state_path   => '/srv/osmosis/state.txt',
    }

    system::role { 'role::osm::master':
        ensure      => 'present',
        description => 'openstreetmaps db master',
    }

    # Create the spatialdb
    postgresql::spatialdb { 'gis': }
    # Import planet.osm
    osm::planet_import { 'gis':
        input_pbf_file => '/srv/labsdb/planet-latest-osm.pbf',
        require        => Postgresql::Spatialdb['gis']
    }
    osm::planet_sync { 'gis':
        pg_password => hiera('osm::postgresql_osmupdater_pass'),
        period      => 'day',
        hour        => '1',
        minute      => '17',
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

    # FIXME - top-scope var without namespace ($osm_slave_v4), will break in puppet 2.8
    # lint:ignore:variable_scope
    if $osm_slave_v4 {
    # lint:endignore
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
    # FIXME - top-scope var without namespace ($osm_slave_v6), will break in puppet 2.8
    # lint:ignore:variable_scope
    if $osm_slave_v6 {
    # lint:endignore
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

    include rsync::server
    rsync::server::module { 'osm_expired_tiles':
        path    => '/srv/osm_expire',
        comment => 'OpenStreetMap expired tile list',
        uid     => 'postgres',
        gid     => 'postgres',
    }

    ferm::service { 'rsync_from_labs':
        desc   => 'Allow labs machines to get the expired OSM tile list',
        prio   => '50',
        proto  => 'tcp',
        port   => 873,
        srange => '($EQIAD_PRIVATE_LABS_INSTANCES1_A_EQIAD $EQIAD_PRIVATE_LABS_INSTANCES1_B_EQIAD $EQIAD_PRIVATE_LABS_INSTANCES1_C_EQIAD $EQIAD_PRIVATE_LABS_INSTANCES1_D_EQIAD)',
    }
    nrpe::monitor_service { 'rsync_server_running':
        description  => 'Check if rsync server is running',
        nrpe_command => "/usr/lib/nagios/plugins/check_procs -w 1:1 -c 1:1 -C rsync --ereg-argument-array '/usr/bin/rsync --no-detach --daemon'",
    }
}

