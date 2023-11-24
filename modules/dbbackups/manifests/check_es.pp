# SPDX-License-Identifier: Apache-2.0
# If enabled, setups a systemd timer that checks the metadata database for all active ES
# (content databases) recent backups and alerts if it took more than one the given amount
# of hours by email (DBAs communicated this is the prefered method at the time, something
# else could be done in the future). Defined as a resource in case several checks with
# different parameters wants to be set.
#
# * enabled: Boolean value, if true, the alert is active and will be triggered weekly. If
#            false, the systemd timer will be disabled and won't perform the check nor
#            send any email.
# * max_hours: Float value with the maximum amount of hours of backup runtime, after which
#              the alert will trigger.
# * email: Email address of where the email will be sent.
# * config_file: Unix path of where to find the MySQL connection parameters ini file

define dbbackups::check_es (
    Boolean $enabled,
    Float[0] $max_hours,
    String $email,
    Stdlib::Unixpath $config_file = '/etc/wmfbackups/backups_check.ini'
) {
    if $enabled {
        $ensure_file = file
        ensure_packages('wmfbackups-check')
    } else {
        $ensure_file = absent
    }

    file { "/etc/default/${title}":
        ensure  => $ensure_file,
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        content => template('dbbackups/check-es-config.erb'),
    }

    # remove old config file
    file { '/etc/wmfbackups/my.cnf':
        ensure  => absent,
    }

    if $enabled {
        $ensure_job = 'present'
    } else {
        $ensure_job = 'absent'
    }

    # We believe a weekly schedule should be enough, will add configurability if the needs change.
    # Thursdays UTC mornings looks like a good time (weekly backups start on Tuesdays)
    systemd::timer::job { $title:
        ensure           => $ensure_job,
        user             => 'root',
        description      => 'Checks and alerts by email if ES backups are too slow',
        command          => '/usr/bin/check-dbbackup-time',
        environment_file => "/etc/default/${title}",
        interval         => {'start' => 'OnCalendar', 'interval' => 'Thu *-*-* 01:00:00'},
        require          => [
            File["/etc/default/${title}"],
            Package['wmfbackups-check'],
            File[$config_file]
        ]
    }
}
