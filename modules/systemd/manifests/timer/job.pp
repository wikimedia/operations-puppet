# == Define: systemd::timer::job
#
# Generic wrapper around the basic timer definition that adds log handling
# and monitoring for defining recurring jobs, much like crons in non-systemd
# world
#
# [*description*]
#   Description to place in the systemd unit.
#
# [*command*]
#   Command to be executed periodically.
#
# [*interval*]
#   Systemd interval to use. See Systemd::Timer::Schedule for the format.
#
# [*user*]
#   User that runs the Systemd unit.
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
#   Default: admins
#
#  [*logging_enabled*]
#   If true, log directories are created, rsyslog/logrotate rules are created.
#   Default: true
#
#  [*logfile_basedir*]
#   Base directory where to store the syslog output of the
#   running unit.
#   Default: "/var/log/${title}"
#
#  [*logfile_name*]
#   The filename of the file storing the syslog output of
#   the running unit.
#   Default: $title.log
#
#  [*logfile_owner*]
#   The user that owns the logfile. If undef, the value of $user will be used.
#   Default: undef
#
#  [*logfile_group*]
#   The group that owns the logfile.
#   Default:  root''
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
#  [*syslog_identifier*]
#   Adds the SyslogIdentifier parameter to the systemd unit to
#   override the default behavior, namely using the program name.
#   This is particularly useful when multiple timers are scheduled
#   using the same program but with different parameters. Without
#   an explicit SyslogIdentifier in fact they would end up sharing
#   the same identifier and rsyslog rules wouldn't work anymore.
#   Default: undef
#
define systemd::timer::job(
    String $description,
    String $command,
    # TODO: add type definition once we move past puppet 4.10, see https://tickets.puppetlabs.com/browse/PUP-7650
    $interval,
    String $user,
    Hash[String, String] $environment = {},
    Boolean $monitoring_enabled = true,
    String $monitoring_contact_groups = 'admins',
    Boolean $logging_enabled = true,
    String $logfile_basedir = "/var/log/${title}",
    String $logfile_name = "${title}.log",
    Optional[String] $logfile_owner = undef,
    String $logfile_group = 'root',
    Enum['user', 'group', 'all'] $logfile_perms = 'all',
    Boolean $syslog_force_stop = true,
    Optional[String] $syslog_identifier = undef,
    Wmflib::Ensure $ensure = 'present',
) {
    $log_owner = $logfile_owner ? {
        undef   => $user,
        default => $logfile_owner
    }
    systemd::unit { "${title}.service":
        ensure  => $ensure,
        content => template('systemd/timer_service.erb'),
    }

    systemd::timer { $title:
        ensure          => $ensure,
        timer_intervals => [$interval],
        unit_name       => "${title}.service",
    }

    if $logging_enabled {
        systemd::syslog { $title:
            ensure       => $ensure,
            base_dir     => $logfile_basedir,
            log_filename => $logfile_name,
            owner        => $log_owner,
            group        => $logfile_group,
            readable_by  => $logfile_perms,
            force_stop   => $syslog_force_stop,
        }
    }


    if $monitoring_enabled {
        # T225268 - always provision NRPE plugin script
        require ::systemd::timer::nrpe_plugin

        nrpe::monitor_service { "check_${title}_status":
            ensure         => $ensure,
            description    => "Check the last execution of ${title}",
            nrpe_command   => "/usr/local/lib/nagios/plugins/check_systemd_unit_status ${title}",
            check_interval => 10,
            retries        => 2,
            contact_group  => $monitoring_contact_groups,
        }
    }
}
