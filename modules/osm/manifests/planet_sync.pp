#
# Definition: osm::planet_sync
#
# This definition provides a way to sync planet_osm in a gis enabled db
#
# Parameters:
#   $pg_password
#      PostgreSQL password
#   $ensure
#      present or absent, just like for standard resources
#   $osmosis_dir
#      Directory that stores osmosis data, including replication state
#   $expire_dir
#      Directory for expiry files
#   $period
#      OSM replication interval: 'minute', 'hour' or 'day'
#   $hour
#      Hour for cronjob, format is the same as for cron resource
#   $minute
#      Minute for cronjob, format is the same as for cron resource
#   $proxy
#      Web proxy for accessing the outside of the cluster
#   $flat_nodes
#      Whether osm2pgsql --flat-nodes parameter should be used
#   $expire_levels
#      For which levels should expiry files be generated. Corresponds to
#      osm2pgslq option -e and can be in format "<level>" or
#      "<from level>-<to level>"
#   $memory_limit
#      Memory in megabytes osm2pgsql should occupy
#   $num_threads
#      Number of threads to use during sync
#
# Actions:
#   sync with planet.osm
#
# Requires:
#   Class['postgresql::postgis']
#   define['postgresql::spatialdb']
#
# Sample Usage:
#  osm::planet_sync { 'mydb': }
define osm::planet_sync(
                $pg_password,
                $ensure=present,
                $osmosis_dir='/srv/osmosis',
                $expire_dir='/srv/osm_expire',
                $period='minute',
                $hour='*',
                $minute='*/30',
                $proxy='webproxy.eqiad.wmnet:8080',
                $flat_nodes=false,
                $expire_levels='15',
                $memory_limit=floor($::memoryfree_mb)/10,
                $num_threads=$::processorcount,
) {
    include ::osm::users

    file { '/srv/downloads':
        ensure => 'directory',
        owner  => 'osmupdater',
        group  => 'osm',
        mode   => '0755',
    }

    file { $expire_dir:
        ensure => directory,
        owner  => 'osmupdater',
        group  => 'osm',
        mode   => '0755',
    }

    file { $osmosis_dir:
        ensure => directory,
        owner  => 'osmupdater',
        group  => 'osm',
        mode   => '0755',
    }

    file { '/usr/local/bin/replicate-osm':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        content => template('osm/replicate-osm.erb'),
    }

    file { "${osmosis_dir}/configuration.txt":
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('osm/osmosis_configuration.txt.erb'),
    }

    cron { "planet_sync-${name}":
        command     => '/usr/local/bin/replicate-osm > /tmp/osm2pgsql.log 2>&1',
        user        => 'osmupdater',
        hour        => $hour,
        minute      => $minute,
        environment => "PGPASS=${pg_password}",
    }
    cron { "expire_old_planet_syncs-${name}":
        ensure  => $ensure,
        command => "/usr/bin/find ${expire_dir} -mtime +5 -exec rm {} \\;",
        user    => 'osmupdater',
        hour    => $hour,
        minute  => $minute,
    }
}
