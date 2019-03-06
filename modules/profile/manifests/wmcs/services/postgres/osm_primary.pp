
class profile::wmcs::services::postgres::osm_primary (
    $osm_password = hiera('profile::wmcs::services::postgres::osm_password'),
    $kolossos_password = hiera('profile::wmcs::services::postgres::kolossos_password'),
    $aude_password = hiera('profile::wmcs::services::postgres::aude_password'),
    $planemad_password = hiera('profile::wmcs::services::postgres::planemad_password'),
){
    include profile::wmcs::services::postgres::primary
    class {'osm': }

    postgresql::user { 'prometheus@localhost':
        user     => 'prometheus',
        database => 'postgres',
        type     => 'local',
        method   => 'peer',
    }

    postgresql::user { 'osmupdater':
        user     => 'osmupdater',
        database => 'gis',
        type     => 'local',
        method   => 'peer',
    }

    class { 'osm::prometheus':
        state_path      => '/srv/osmosis/state.txt',
        prometheus_path => '/var/lib/prometheus/node.d/osm_sync_lag.prom',
    }

    # Create the spatialdb
    postgresql::spatialdb { 'gis': }
    osm::planet_sync { 'gis':
        use_proxy  => true,
        proxy_host => "webproxy.${::site}.wmnet",
        proxy_port => 8080,
        period     => 'day',
        hour       => '1',
        minute     => '17',
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

    # OSM user
    postgresql::user { 'osm@labs':
            ensure   => 'present',
            user     => 'osm',
            password => $osm_password,
            cidr     => '10.68.16.0/21',
            type     => 'host',
            method   => 'trust',
            database => 'gis',
    }
    postgresql::user { 'osm@eqiad1r':
            ensure   => 'present',
            user     => 'osm',
            password => $osm_password,
            cidr     => '172.16.0.0/21',
            type     => 'host',
            method   => 'trust',
            database => 'gis',
    }

    # Specific users and databases
    postgresql::spatialdb { 'u_kolossos': }
    postgresql::user { 'kolossos@labs':
            ensure   => 'present',
            user     => 'kolossos',
            password => $kolossos_password,
            cidr     => '10.68.16.0/21',
            type     => 'host',
            method   => 'md5',
            database => 'u_kolossos',
    }
    postgresql::user { 'kolossos@eqiad1r':
            ensure   => 'present',
            user     => 'kolossos',
            password => $kolossos_password,
            cidr     => '172.16.0.0/21',
            type     => 'host',
            method   => 'md5',
            database => 'u_kolossos',
    }

    postgresql::spatialdb { 'u_aude': }
    postgresql::user { 'aude@labs':
            ensure   => 'present',
            user     => 'aude',
            password => $aude_password,
            cidr     => '10.68.16.0/21',
            type     => 'host',
            method   => 'md5',
            database => 'u_aude',
    }
    postgresql::user { 'aude@eqiad1r':
            ensure   => 'present',
            user     => 'aude',
            password => $aude_password,
            cidr     => '172.16.0.0/21',
            type     => 'host',
            method   => 'md5',
            database => 'u_aude',
    }

    postgresql::spatialdb { 'wikimaps_atlas': }
    postgresql::user { 'planemad@labs':
            ensure   => 'present',
            user     => 'planemad',
            password => $planemad_password,
            cidr     => '10.68.16.0/21',
            type     => 'host',
            method   => 'md5',
            database => 'wikimaps_atlas',
    }
    postgresql::user { 'planemad@eqiad1r':
            ensure   => 'present',
            user     => 'planemad',
            password => $planemad_password,
            cidr     => '172.16.0.0/21',
            type     => 'host',
            method   => 'md5',
            database => 'wikimaps_atlas',
    }

    class {'rsync::server': }
    rsync::server::module { 'osm_expired_tiles':
        path    => '/srv/osm_expire',
        comment => 'OpenStreetMap expired tile list',
        uid     => 'postgres',
        gid     => 'postgres',
    }

    nrpe::monitor_service { 'rsync_server_running':
        description  => 'Check if rsync server is running',
        nrpe_command => "/usr/lib/nagios/plugins/check_procs \
                         -w 1:1 -c 1:1 -C rsync --ereg-argument-array \
                         '/usr/bin/rsync --daemon --no-detach'",
    }
}
