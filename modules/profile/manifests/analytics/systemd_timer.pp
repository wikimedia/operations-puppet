# == Define: profile::analytics::systemd_timer
#
# This is prototype of a possible replacement (or evolution) of the
# Analytics' cron job definitions.
#
# [*description*]
#   Description to place in the systemd unit.
#
# [*command*]
#   Command to be executed periodically.
#
# [*interval*]
#   Systemd interval to use. Format: DayOfWeek Year-Month-Day Hour:Minute:Second
#
# [*user*]
#   User that runs the Systemd unit.
#   Default: 'hdfs'
#
#  [*environment*]
#   Hash containing 'Environment=' related values to insert in the
#   Systemd unit.
#
#  [*monitoring_enabled*]
#   Periodically check the last execution of the unit and alarm if it ended
#   up in a failed state.
#   Default: true
#
define profile::analytics::systemd_timer(
    $description,
    $command,
    $interval,
    $user = 'hdfs',
    $environment = {},
    $monitoring_enabled = true,
) {

    systemd::unit { "${title}.service":
        ensure  => 'present',
        content => template('profile/analytics/systemd_timer.systemd.erb'),
    }

    systemd::timer { $title:
        timer_intervals => [{
            'start'    => 'OnCalendar',
            'interval' => $interval
            }],
        unit_name       => "${title}.service",
    }

    if monitoring_enabled {
        if !defined(File['/usr/local/lib/nagios/plugins/check_systemd_unit_status']) {
            file { '/usr/local/lib/nagios/plugins/check_systemd_unit_status':
                ensure => present,
                source => 'puppet:///modules/profile/analytics/systemd_timer/check_systemd_unit_status',
                mode   => '0555',
                owner  => 'root',
                group  => 'root',
            }
        }

        nrpe::monitor_service { "check_${title}_status":
            description    => "Check the last execution of ${title}",
            nrpe_command   => "/usr/local/lib/nagios/plugins/check_systemd_unit_status ${title}",
            check_interval => 600,
            retries        => 2,
            contact_group  => 'analytics',
            require        => File['/usr/local/lib/nagios/plugins/check_systemd_unit_status'],
        }
    }
}