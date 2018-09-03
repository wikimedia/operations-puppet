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
define profile::analytics::systemd_timer(
    $description,
    $command,
    $interval,
    $user = 'hdfs',
    $environment = {},
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
}