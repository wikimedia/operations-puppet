# === Parameters
#
# [*postgres_users*]
#   Hash of postgresql users to create.
#   Default: {}
#
# [*postgres_users_private*]
#   Hash of postgresql users to create.
#   This hash will be merged with $postgres_users to allow configuration of
#   private parameters (eg. passwords) in private repo while allowing non
#   private parameters to be published.
#   Default: {}
#
# [*spatial_dbs*]
#   Array of `postgresql::spatialdb` to create.
#   Default: []
#
class role::osm::master(
    $postgres_users         = {},
    $postgres_users_private = {},
    $spacial_dbs            = [],
) {
    include role::osm::common
    include postgresql::postgis
    include osm
    include passwords::osm
    include base::firewall

    validate_hash($postgres_users)
    validate_hash($postgres_users_private)
    validate_array($spacial_dbs)

    class { 'postgresql::master':
        includes => 'tuning.conf',
        root_dir => $role::osm::common::root_dir,
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

    $merged_postgres_users = merge($postgres_users, $postgres_users_private)
    $user_defaults = {
        cidr   =>   '10.68.16.0/21',
        type   =>   'host',
        method =>   'md5',
    }
    create_resources(postgresql::user, $merged_postgres_users, $user_defaults)

    # databases
    postgresql::spatialdb { $spacial_dbs: }

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

