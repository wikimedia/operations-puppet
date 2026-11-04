# SPDX-License-Identifier: Apache-2.0
# == Define: profile::trafficserver::logs
#
# Logging helpers and icinga checks for Trafficserver.
#
define profile::trafficserver::logs(
    String                    $user,
    Array[TrafficServer::Log] $logs,
    String                    $conftool_service = 'ats-be',
) {
    $logs.each |TrafficServer::Log $log| {
        if $log['mode'] == 'ascii_pipe' {
            fifo_log_demux::instance { $log['filename']:
                ensure          => $log['ensure'],
                user            => $user,
                fifo            => "/var/log/trafficserver/${log['filename']}.pipe",
                socket          => "/run/trafficserver/${log['filename']}.sock",
                prometheus_port => $log['prometheus_port'],
                wanted_by       => 'trafficserver.service',
            }

            profile::trafficserver::nrpe_monitor_script { "check_trafficserver_log_fifo_${log['filename']}_backend":
                ensure    => $log['ensure'],
                sudo_user => 'root',
                checkname => 'check_trafficserver_log_fifo',
                args      => "--socket /run/trafficserver/${log['filename']}.sock --service ${conftool_service}",
                extension => 'py',
                timeout   => 90,
            }
        }
    }
}
