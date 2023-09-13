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
#
define dbbackups::check_es (
    $enabled,
    $max_hours,
    $email,
    $db_host,
    $db_user,
    $db_password,
    $db_database,
) {
    $config_file = '/etc/wmfbackups/my.cnf'

    if $enabled {
        $ensure = 'present'
    } else {
        $ensure = 'absent'
    }

    file { "/etc/defaults/${title}":
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        content => template('dbbackups/check-es-config.erb'),
    }

    file { $config_file:
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        content => template('dbbackups/my.cnf.erb'),
    }

    file { '/usr/bin/check-dbbackup-time':
        ensure => $ensure,
        owner  => 'root',
        group  => 'root',
        mode   => '0540',
        source => 'puppet:///modules/dbbackups/check_dbbackup_time.py'
    }

    # We believe a weekly schedule should be enough, will add configurability if the needs change.
    # Thursdays UTC mornings looks like a good time (weekly backups start on Tuesdays)
    systemd::timer::job { $title:
        ensure           => $ensure,
        user             => 'root',
        description      => 'Checks and alerts by email if ES backups are too slow',
        command          => '/usr/bin/check-dbbackup-time',
        environment_file => "/etc/defaults/${title}",
        interval         => {'start' => 'OnCalendar', 'interval' => 'Thu *-*-* 01:00:00'},
        require          => [ File["/etc/defaults/${title}"], File['/usr/bin/check-dbbackup-time'] ]
    }
}
