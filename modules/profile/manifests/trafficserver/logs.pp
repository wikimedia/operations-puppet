define profile::trafficserver::logs(
    String $user,
    String $instance_name,
    Array[TrafficServer::Log] $logs,
    TrafficServer::Paths $paths,
    String $service_name = 'trafficserver',
    String $conftool_service = 'ats-be',
    String $atslog_filename = 'notpurge',
) {
    $logs.each |TrafficServer::Log $log| {
        if $log['mode'] == 'ascii_pipe' {
            fifo_log_demux::instance { $log['filename']:
                ensure    => $log['ensure'],
                user      => $user,
                fifo      => "${paths['logdir']}/${log['filename']}.pipe",
                socket    => "${paths['runtimedir']}/${log['filename']}.sock",
                wanted_by => "${service_name}.service",
            }

            profile::trafficserver::nrpe_monitor_script { "check_trafficserver_log_fifo_${log['filename']}_${instance_name}":
                ensure    => $log['ensure'],
                sudo_user => 'root',
                checkname => 'check_trafficserver_log_fifo',
                args      => "--socket ${paths['runtimedir']}/${log['filename']}.sock --service ${conftool_service}",
                extension => 'py',
                timeout   => 90,
            }
        }
    }

    # Wrapper script to print ATS logs to stdout using fifo-log-tailer
    file { "/usr/local/bin/atslog-${instance_name}":
        ensure  => present,
        content => template('profile/trafficserver/atslog.sh.erb'),
        mode    => '0555',
        owner   => 'root',
        group   => 'root',
    }

    # Icinga check to ensure we are not skipping logs due to lack of buffer
    # space - T237608
    nrpe::monitor_service { "${service_name}_skipped_logs":
        description  => "Logs skipped by ${service_name}",
        nrpe_command => "/usr/local/lib/nagios/plugins/check_journal_pattern '1 hour ago' 'NOTE: Skipping the current log entry for ' ${service_name}",
        notes_url    => 'https://wikitech.wikimedia.org/wiki/ATS',
    }
}
