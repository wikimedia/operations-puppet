#
# Definition: osm::planet_sync
#
# This definition provides a way to sync planet_osm in a gis enabled db
# Important: it's required to select whitch replication tool will be used:
# imposm3 or osm2pgsql
#
# Parameters:
#   $engine
#       Engine to use for syncing - either osm2pgsql or imposm3
#   $use_proxy
#       present or absent, just like for standard resources
#   $proxy_host
#       present or absent, just like for standard resources
#   $proxy_port
#       present or absent, just like for standard resources
#   $ensure
#       present or absent, just like for standard resources
#   $expire_dir
#       Directory for expiry files
#   $download_dir
#       Directory for downloaded files
#   $period
#       OSM replication interval: 'minute', 'hour' or 'day'
#   $hours
#       Hour for cronjob, format is the same as for cron resource
#   $day
#       Day for cronjob, format is the same as for cron resource
#   $minute
#       Minute for cronjob, format is the same as for cron resource
#   $flat_nodes
#      [osm2pgsql] Whether osm2pgsql --flat-nodes parameter should be used
#   $expire_levels
#       For which levels should expiry files be generated.
#       [imposm] corresponds to
#       [osm2pgsql] Corresponds to osm2pgslq option -e and can be in format "<level>" or
#       "<from level>-<to level>"
#   $memory_limit
#       [osm2pgsql] Memory in megabytes osm2pgsql should occupy
#   $num_threads
#       [osm2pgsql] Number of threads to use during sync
#   $postreplicate_command
#       command to run after replication of OSM data
#   $input_reader_format
#       [osm2pgsql] Format passed to osm2pgsql as --input-reader parameter. osm2pgsql < 0.90
#       needs 'libxml2' (which is default) and osm2pgsql >= 0.90 needs 'xml'.
#   $disable_replication_cron
#       [imposm] disable OSM replication only because for imposm tile generation
#       and OSM replication are decoupled
#       [osm2pgsql] disables cron that executes OSM replication and tile generation
#   $disable_tile_generation_cron
#       [imposm] disable cron that only run tile generation
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
    Enum['osm2pgsql', 'imposm3'] $engine,
    Boolean $use_proxy,
    String $proxy_host,
    String $swift_key_id,
    String $swift_password,
    String $tegola_swift_container,
    Stdlib::Port $proxy_port,
    Wmflib::Ensure $ensure                  = present,
    String $expire_dir                      = '/srv/osm_expire',
    String $download_dir                    = '/srv/downloads',
    String $period                          = 'minute',
    Variant[String, Array[Integer]] $hours  = [],
    Variant[String,Integer] $day            = '*',
    Variant[String,Integer] $minute         = '*/30',
    Boolean $flat_nodes                     = false,
    Integer $expire_levels                  = 15,
    Integer $memory_limit                   = floor($::memorysize_mb) / 12,
    Integer $num_threads                    = $::processorcount,
    Optional[String] $postreplicate_command = undef,
    String $input_reader_format             = 'xml',
    Boolean $disable_replication_cron       = false,
    Boolean $disable_tile_generation_cron   = false,
    String $eventgate_endpoint              = 'https://eventgate-main.discovery.wmnet:4492/v1/events',
) {
    include ::osm::users

    file { $download_dir:
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

    $osm_log_dir = $engine ? {
        'imposm3' => '/var/log/imposm',
        'osm2pgsql' => '/var/log/osmosis'
    }

    $tile_generation_command = $engine ? {
        'imposm3' => "${postreplicate_command} >> ${osm_log_dir}/imposm.log 2>&1",
        'osm2pgsql' => "/usr/local/bin/replicate-osm >> ${osm_log_dir}/osm2pgsql.log 2>&1"
    }

    case $engine {
        'imposm3': {
            class { 'osm::imposm3':
                ensure                   => $ensure,
                proxy_host               => $proxy_host,
                proxy_port               => $proxy_port,
                osm_log_dir              => $osm_log_dir,
                expire_dir               => $expire_dir,
                expire_levels            => $expire_levels,
                disable_replication_cron => $disable_replication_cron,
                eventgate_endpoint       => $eventgate_endpoint,
                swift_key_id             => $swift_key_id,
                swift_password           => $swift_password,
                tegola_swift_container   => $tegola_swift_container
            }
        }
        'osm2pgsql': {
            class { 'osm::osm2pgsql':
                use_proxy             => $use_proxy,
                proxy_host            => $proxy_host,
                proxy_port            => $proxy_port,
                osm_log_dir           => $osm_log_dir,
                flat_nodes            => $flat_nodes,
                period                => $period,
                expire_dir            => $expire_dir,
                expire_levels         => $expire_levels,
                memory_limit          => $memory_limit,
                num_threads           => $num_threads,
                input_reader_format   => $input_reader_format,
                postreplicate_command => $postreplicate_command,
            }
        }
        default: {
            fail("Unsupported sync engine ${engine}")
        }
    }

    file { $osm_log_dir:
        ensure => directory,
        owner  => 'osmupdater',
        group  => 'osmupdater',
        mode   => '0755',
    }

    $ensure_cron = $disable_tile_generation_cron ? {
        true    => absent,
        default => $ensure,
    }

    cron { "planet_sync_tile_generation-${name}":
        ensure   => $ensure_cron,
        command  => $tile_generation_command,
        user     => 'osmupdater',
        monthday => $day,
        hour     => $hours,
        minute   => $minute,
    }

    cron { "expire_old_planet_syncs-${name}":
        ensure  => $ensure,
        command => "/usr/bin/find ${expire_dir} -mtime +30 -type f -exec rm {} \\;",
        user    => 'osmupdater',
        hour    => $hours,
        minute  => $minute,
    }
}
