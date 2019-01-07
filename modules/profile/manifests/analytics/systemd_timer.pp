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
#  [*monitoring_contact_groups*]
#   The monitoring's contact group to send the alarm to.
#   Default: analytics
#
#  [*logfile_basedir*]
#   Base directory where to store the syslog output of the
#   running unit.
#   Default: "/var/log/${title}"
#
#  [*logfile_name*]
#   The filename of the file storing the syslog output of
#   the running unit. If set to undef, it avoids the deployment
#   of rsyslog/logrotate rules (relying only on journald).
#   Default: undef
#
#  [*logfile_owner*]
#   The user that owns the logfile.
#   Default: 'hdfs'
#
#  [*logfile_group*]
#   The group that owns the logfile.
#   Default: 'hdfs'
#
#  [*logfile_perms*]
#   The UNIX file permissions to set on the log file.
#   Check systemd::syslog for more info about the available options.
#   Default: 'all'
#
#  [*syslog_force_stop*]
#   Force logs to be written into the logfile but not in
#   syslog/daemon.log. This is particularly useful for units that
#   need to log a lot of information, since it prevents a duplication
#   of space consumed on disk.
#   Default: true
#
define profile::analytics::systemd_timer(
    $description,
    $command,
    $interval,
    $user = 'hdfs',
    $environment = {},
    $monitoring_enabled = true,
    $monitoring_contact_groups = 'analytics',
    $logfile_basedir = "/var/log/${title}",
    $logfile_name = undef,
    $logfile_owner = 'hdfs',
    $logfile_group = 'hdfs',
    $logfile_perms = 'all',
    $syslog_force_stop = true,
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

    if $logfile_name {
        systemd::syslog { $title:
            base_dir     => $logfile_basedir,
            log_filename => $logfile_name,
            owner        => $logfile_owner,
            group        => $logfile_group,
            readable_by  => $logfile_perms,
            force_stop   => $syslog_force_stop,
        }
    }


    if $monitoring_enabled {
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
            check_interval => 10,
            retries        => 2,
            contact_group  => $monitoring_contact_groups,
            require        => File['/usr/local/lib/nagios/plugins/check_systemd_unit_status'],
        }
    }
}