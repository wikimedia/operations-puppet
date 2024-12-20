# SPDX-License-Identifier: Apache-2.0
#
# Definition: osm::planet_sync
#
# This definition provides a way to sync planet_osm in a gis enabled db
#
# Parameters:
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
#   $expire_levels
#       For which levels should expiry files be generated.
#   $postreplicate_command
#       command to run after replication of OSM data
#   $disable_replication_timer
#       Don't run the systemd timer that initiates OSM replication
#   $disable_tile_generation_timer
#       Don't run the systemd timer that initiates tile generation
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
    String $swift_key_id,
    String $swift_password,
    String $tegola_swift_container,
    Stdlib::Port $proxy_port,
    Wmflib::Ensure $ensure                  = present,
    Stdlib::Unixpath $expire_dir            = '/srv/osm_expire',
    Stdlib::Unixpath $download_dir          = '/srv/downloads',
    String $period                          = 'minute',
    Variant[String,Integer] $hours          = '*',
    Variant[String,Integer] $day            = '*',
    Variant[String,Integer] $minute         = '*/30',
    Boolean $flat_nodes                     = false,
    Integer $expire_levels                  = 15,
    Optional[String] $postreplicate_command = undef,
    Optional[String] $postreplicate_user    = 'osmupdater',
    Boolean $disable_replication_timer      = false,
    Boolean $disable_tile_generation_timer  = false,
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

    $osm_log_dir = '/var/log/imposm'
    $osm_log_file = 'imposm.log'
    $tile_generation_command = $postreplicate_command

    class { 'osm::imposm3':
        ensure                    => $ensure,
        proxy_host                => $proxy_host,
        proxy_port                => $proxy_port,
        osm_log_dir               => $osm_log_dir,
        expire_dir                => $expire_dir,
        expire_levels             => $expire_levels,
        disable_replication_timer => $disable_replication_timer,
        eventgate_endpoint        => $eventgate_endpoint,
        swift_key_id              => $swift_key_id,
        swift_password            => $swift_password,
        tegola_swift_container    => $tegola_swift_container
    }

    file { $osm_log_dir:
        ensure => directory,
        owner  => 'osmupdater',
        group  => 'osmupdater',
        mode   => '0755',
    }

    if $tile_generation_command {
        $ensure_timer = $disable_tile_generation_timer ? {
            true    => absent,
            default => $ensure,
        }

        systemd::timer::job { "planet_sync_tile_generation-${name}":
            ensure          => $ensure_timer,
            description     => "Run plant sync tile generation for ${name}",
            user            => $postreplicate_user,
            command         => $tile_generation_command,
            logfile_basedir => $osm_log_dir,
            logfile_name    => $osm_log_file,
            interval        => {'start' => 'OnCalendar', 'interval' => "*-*-${day} ${hours}:${minute}:00"},
        }
    }

    systemd::timer::job { "expire_old_planet_syncs-${name}":
        ensure      => $ensure,
        description => "Expire old planet syncs for ${name}",
        user        => 'osmupdater',
        command     => "/usr/bin/find ${expire_dir} -mtime +30 -type f -delete",
        interval    => {'start' => 'OnCalendar', 'interval' => "*-*-* ${hours}:${minute}:00"}
    }
}
