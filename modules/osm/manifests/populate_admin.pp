# SPDX-License-Identifier: Apache-2.0
define osm::populate_admin (
    Wmflib::Ensure $ensure       = present,
    Boolean $disable_admin_timer = false,
    Integer $hour                = 0,
    Integer $minute              = 1,
    String $weekday              = 'Tue',
    String $log_dir              = '/var/log/osm'
) {

    $ensure_timer = $disable_admin_timer ? {
        true    => absent,
        default => $ensure,
    }

    file { $log_dir:
        ensure => directory,
        owner  => 'postgres',
        group  => 'postgres',
        mode   => '0755',
    }

    file { '/usr/local/bin/osm_populate_admin.sh':
        ensure  => directory,
        owner   => 'postgres',
        group   => 'postgres',
        mode    => '0755',
        content => template('osm/osm_populate_admin'),
    }

    systemd::timer::job { "populate_admin-${title}":
        ensure      => $ensure_timer,
        description => 'Ensure correct grants in Postgresql for OSM',
        command     => '/usr/local/bin/osm_populate_admin.sh',
        user        => 'postgres',
        interval    => {'start' => 'OnCalendar', 'interval' => "${weekday} *-*-* ${hour}:${minute}:00"}
    }

    logrotate::rule { "populate_admin-${title}":
        ensure     => $ensure_timer,
        file_glob  => "${log_dir}/populate_admin.log",
        frequency  => 'weekly',
        missing_ok => true,
        rotate     => 4,
        compress   => true,
    }

}
