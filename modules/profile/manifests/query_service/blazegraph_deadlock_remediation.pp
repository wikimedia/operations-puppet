# SPDX-License-Identifier: Apache-2.0
# @summary Blazegraph deadlock auto-remediation (T242453)
#
# Deploys a systemd timer that checks the local JVM thread count every
# few minutes and restarts blazegraph if a deadlock is detected.
#
# Deadlocked Blazegraph hosts increase in threads a ton,
# and can hit north of 2k+.
# Healthy hosts generally stay in the 300-600 thread range.

# Includes per-host cooldown (default 1h) to limit
# how much a given host can be auto-restarted.

class profile::query_service::blazegraph_deadlock_remediation (
    Boolean $enabled = lookup('profile::query_service::blazegraph_deadlock_remediation::enabled', {'default_value' => false}),
    Integer $threshold = lookup('profile::query_service::blazegraph_deadlock_remediation::threshold', {'default_value' => 1200}),
    Integer $cooldown_seconds = lookup('profile::query_service::blazegraph_deadlock_remediation::cooldown_seconds', {'default_value' => 1800}),
    Integer $check_interval_minutes = lookup('profile::query_service::blazegraph_deadlock_remediation::check_interval_minutes', {'default_value' => 5}),
    String $deploy_name = lookup('profile::query_service::deploy_name'),
    Stdlib::Port $prometheus_agent_port = lookup('profile::query_service::blazegraph_deadlock_remediation::prometheus_agent_port', {'default_value' => 9102}),
) {
    $service_name = "${deploy_name}-blazegraph"
    $log_file = '/var/log/wdqs-blazegraph-deadlock-remediation.log'
    $script_path = '/usr/local/sbin/wdqs-blazegraph-deadlock-check'

    if $enabled {
        file { $script_path:
            ensure  => file,
            owner   => 'root',
            group   => 'root',
            mode    => '0755',
            content => template('profile/query_service/blazegraph-deadlock-check.sh.erb'),
        }

        systemd::timer::job { 'wdqs-blazegraph-deadlock-check':
            description          => 'Check for Blazegraph instability and auto-restart if detected (T242453)',
            command              => $script_path,
            interval             => {
                'start'    => 'OnCalendar',
                'interval' => "*-*-* *:00/${check_interval_minutes}:00",
            },
            max_runtime_seconds  => 120,
            user                 => 'root',
            logging_enabled      => false,
            monitoring_enabled   => true,
            monitoring_notes_url => 'https://wikitech.wikimedia.org/wiki/Wikidata_Query_Service/Runbook#Blazegraph_deadlock',
            require              => File[$script_path],
        }
    } else {
        file { $script_path:
            ensure => absent,
        }

        systemd::timer::job { 'wdqs-blazegraph-deadlock-check':
            ensure      => absent,
            description => 'Check for Blazegraph deadlock and auto-restart if detected (T242453)',
            command     => $script_path,
            interval    => {
                'start'    => 'OnCalendar',
                'interval' => '*-*-* *:00/5:00',
            },
            user        => 'root',
        }
    }
}
