# SPDX-License-Identifier: Apache-2.0
# Definition: osm::import_waterlines
#
# Sets up waterlines
# Parameters:
#    * database - postgres database name
#    * use_proxy - when set to true, proxy is used
#    * proxy - web proxy used for downloading shapefiles
#    * disable_waterlines_import_timer - if enabled, don't run the import periodically
class osm::import_waterlines (
    Boolean $use_proxy,
    String $proxy_host,
    Stdlib::Port $proxy_port,
    Boolean $disable_waterlines_import_timer,
    String $database = 'gis',
) {

    $logfile_basedir = '/var/log'
    $log_dir = "${logfile_basedir}/waterlines"

    $proxy_opt = $use_proxy ? {
        false   => '',
        default => "-x ${proxy_host}:${proxy_port}",
    }

    file { '/usr/local/bin/import_waterlines':
        ensure  => present,
        mode    => '0555',
        content => template('osm/import_waterlines.erb'),
    }

    file { $log_dir:
        ensure => directory,
        owner  => 'postgres',
        group  => 'postgres',
        mode   => '0755',
    }

    if $disable_waterlines_import_timer {
        $ensure_waterlines = absent
    } else {
        $ensure_waterlines = present
    }

    systemd::timer::job { 'waterlines':
        ensure          => $ensure_waterlines,
        description     => 'Regular jobs to set up the waterlines',
        user            => 'postgres',
        command         => '/usr/local/bin/import_waterlines',
        logfile_basedir => $logfile_basedir,
        logfile_name    => 'import.log',
        interval        => {'start' => 'OnCalendar', 'interval' => '*-*-01 9:13:00'},
    }

}
