define profile::trafficserver::logs(
    String $user,
    String $instance_name,
    Array[TrafficServer::Log] $logs,
    TrafficServer::Paths $paths,
    String $service_name = 'trafficserver',
    String $atslog_filename = 'notpurge',
) {
    $logs.each |TrafficServer::Log $log| {
        if $log['mode'] == 'ascii_pipe' {
            fifo_log_demux::instance { $log['filename']:
                user      => $user,
                fifo      => "${paths['logdir']}/${log['filename']}.pipe",
                socket    => "${paths['runtimedir']}/${log['filename']}.sock",
                wanted_by => "${service_name}.service",
            }

            profile::trafficserver::nrpe_monitor_script { "check_trafficserver_log_fifo_${log['filename']}_${instance_name}":
                sudo_user => 'root',
                checkname => 'check_trafficserver_log_fifo',
                args      => "${paths['logdir']}/${log['filename']}.pipe",
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
}
