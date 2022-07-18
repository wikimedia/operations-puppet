# SPDX-License-Identifier: Apache-2.0
# Create remote xtrabackup/mariabackup backups
# By using transfer.py
# This class will setup the configuration and software
# needed to trigger new raw backups. If enabled, it
# will set up a systemd timer to schedule it.
# It requires the previous setup of a config at:
# modules/profile/templates/dbbackups/<hostname>.cnf.erb
# If the host has it enabled but the file hasn't been
# setup, puppet run will fail. Either add its custom
# backup configuration (see wmfbackups documentation) or
# disable scheduled backup taking.
# * enabled: Defaults to true. If false, it setups all
#            dependencies, but does not retrieve a schedule
#            configuration nor sets up a timer.
class profile::dbbackups::transfer (
    Boolean $enabled = lookup('profile::dbbackups::transfer::enabled', {'default_value' => true})
) {
    require ::profile::mariadb::wmfmariadbpy
    ensure_packages([
        'wmfbackups-remote',  # will install also wmfmariadbpy-remote and transferpy
    ])

    # we can override transferpy defaults if needed
    file { '/etc/transferpy/transferpy.conf':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/profile/dbbackups/transferpy.conf',
    }

    if $enabled {
        include passwords::mysql::dump
        $stats_user = $passwords::mysql::dump::stats_user
        $stats_password = $passwords::mysql::dump::stats_pass
        # Configuration file where the daily backup routine (source hosts,
        # destination, statistics db is configured
        # Can contain private data like db passwords
        file { '/etc/wmfbackups/remote_backups.cnf':
            ensure    => present,
            owner     => 'root',
            group     => 'root',
            mode      => '0400',
            show_diff => false,
            content   => template("profile/dbbackups/${::hostname}.cnf.erb"),
            require   => Package['wmfbackups-remote'],
        }

        systemd::timer::job { 'database-backups-snapshots':
            ensure      => 'present',
            user        => 'root',
            description => 'Generate mysql snapshot backup batch',
            command     => '/usr/bin/remote-backup-mariadb all',
            interval    => {
                'start'    => 'OnCalendar',
                'interval' => 'Sun,Tue,Wed,Fri *-*-* 19:00:00',
            },
            require     => [
                File['/etc/wmfbackups/remote_backups.cnf'],
                Package['wmfbackups-remote'],
            ]
        }
    } else {
        # remove existing leftovers without dependencies
        file { '/etc/wmfbackups/remote_backups.cnf':
            ensure    => absent,
            show_diff => false,
        }
        systemd::timer::job { 'database-backups-snapshots':
            ensure      => absent,
            description => 'Generate mysql snapshot backup batch',
            user        => 'root',
            command     => '/usr/bin/remote-backup-mariadb all',
            interval    => {
                'start'    => 'OnCalendar',
                'interval' => 'Sun,Tue,Wed,Fri *-*-* 19:00:00',
            },
        }
    }
}
