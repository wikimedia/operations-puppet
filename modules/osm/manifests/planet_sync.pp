#
# Definition: osm::planet_sync
#
# This definition provides a way to sync planet_osm in a gis enabled db
#
# Parameters:
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
                $pg_password,
) {
    include ::osm::users

    file { '/srv/downloads':
        ensure => 'directory',
        owner  => 'osmupdater',
        group  => 'osm',
        mode   => '0775',
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
        command     => "/usr/local/bin/replicate-osm > /tmp/osmosis.log 2>&1",
        user        => 'osmupdater',
        hour        => $hour,
        minute      => $minute,
    }
    cron { "expire_old_planet_syncs-${name}":
        ensure  => $ensure,
        command => "/usr/bin/find ${expire_dir} -mtime +5 -exec rm {} \\;",
        user    => 'osmupdater',
        hour    => $hour,
        minute  => $minute,
        environment => "PGPASSWORD=$pg_password"
    }
}
