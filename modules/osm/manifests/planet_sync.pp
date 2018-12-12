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
#   $input_reader_format
#      Format passed to osm2pgsql as --input-reader parameter. osm2pgsql < 0.90
#      needs 'libxml2' (which is default) and osm2pgsql >= 0.90 needs 'xml'.
#      osm2pgsql == 0.90 is used on jessie only at this point.
#   $postreplicate_command
#      command to run after replication of OSM data
#   $disable_replication_cron
#      usefull to disable replication, for example during a full tile regeneration
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
define osm::planet_sync (
    Boolean $use_proxy,
    String $proxy_host,
    Wmflib::IpPort $proxy_port,
    Wmflib::Ensure $ensure                  = present,
    String $osmosis_dir                     = '/srv/osmosis',
    String $expire_dir                      = '/srv/osm_expire',
    String $period                          = 'minute',
    String $hour                            = '*',
    String $day                             = '*',
    String $minute                          = '*/30',
    Boolean $flat_nodes                     = false,
    String $expire_levels                   = '15',
    Integer $memory_limit                   = floor($::memorysize_mb) / 12,
    Integer $num_threads                    = $::processorcount,
    String $input_reader_format             = os_version('debian >= jessie') ? {
        true    => 'xml',
        default => 'libxml2',
    },
    Optional[String] $postreplicate_command = undef,
    Boolean $disable_replication_cron       = false,
) {
    include ::osm::users

    $osm_log_dir = '/var/log/osmosis'

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
        mode   => '0775',
    }

    file { $osmosis_dir:
        ensure => directory,
        owner  => 'osmupdater',
        group  => 'osm',
        mode   => '0775',
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

    file { $osm_log_dir:
        ensure => directory,
        owner  => 'osmupdater',
        group  => 'osmupdater',
        mode   => '0755',
    }

    logrotate::conf { 'planetsync':
        ensure  => present,
        content => template('osm/planetsync-logrotate.conf.erb'),
    }

    file { "${osmosis_dir}/nodes.bin":
        ensure => present,
        owner  => 'osmupdater',
        group  => 'osm',
        mode   => '0775',
    }

    $ensure_cron = $disable_replication_cron ? {
        true    => absent,
        default => $ensure,
    }

    cron { "planet_sync-${name}":
        ensure   => $ensure_cron,
        command  => "/usr/local/bin/replicate-osm >> ${osm_log_dir}/osm2pgsql.log 2>&1",
        user     => 'osmupdater',
        monthday => $day,
        hour     => $hour,
        minute   => $minute,
    }

    cron { "expire_old_planet_syncs-${name}":
        ensure  => $ensure,
        command => "/usr/bin/find ${expire_dir} -mtime +30 -type f -exec rm {} \\;",
        user    => 'osmupdater',
        hour    => $hour,
        minute  => $minute,
    }
}
