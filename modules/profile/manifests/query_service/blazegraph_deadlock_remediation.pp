# SPDX-License-Identifier: Apache-2.0
# @summary Blazegraph deadlock auto-remediation (T242453)
#
# Deploys a systemd timer that checks local Blazegraph health every few
# minutes and restarts blazegraph if instability is detected.
#
# Two restart criteria (shared cooldown):
#   1. JVM thread count > threshold (deadlock detection)
#   2. Update lag > lag_threshold (stalled updater detection)
#
# Deadlocked Blazegraph hosts spike to 2000+ threads (healthy: 300-600).
# Stalled updaters show growing lag (healthy: seconds; sick: 8+ minutes).
#
# Metrics are fetched with retry + exponential backoff to tolerate transient
# exporter unavailability. On exhausted retries, the check exits cleanly
# (no Icinga alert).

class profile::query_service::blazegraph_deadlock_remediation (
    Boolean $enabled = lookup('profile::query_service::blazegraph_deadlock_remediation::enabled', {'default_value' => false}),
    Integer $threshold = lookup('profile::query_service::blazegraph_deadlock_remediation::threshold', {'default_value' => 1200}),
    Integer $cooldown_seconds = lookup('profile::query_service::blazegraph_deadlock_remediation::cooldown_seconds', {'default_value' => 1800}),
    Integer $check_interval_minutes = lookup('profile::query_service::blazegraph_deadlock_remediation::check_interval_minutes', {'default_value' => 5}),
    String $deploy_name = lookup('profile::query_service::deploy_name'),
    Stdlib::Port $prometheus_agent_port = lookup('profile::query_service::blazegraph_deadlock_remediation::prometheus_agent_port', {'default_value' => 9102}),
    Optional[Stdlib::Port] $updater_metrics_port = lookup('profile::query_service::blazegraph_deadlock_remediation::updater_metrics_port', {'default_value' => 9193}),
    Integer $lag_threshold = lookup('profile::query_service::blazegraph_deadlock_remediation::lag_threshold', {'default_value' => 480}),
    Integer $max_retries = lookup('profile::query_service::blazegraph_deadlock_remediation::max_retries', {'default_value' => 5}),
    Integer $retry_base_delay = lookup('profile::query_service::blazegraph_deadlock_remediation::retry_base_delay', {'default_value' => 10}),
) {
    $service_name = "${deploy_name}-blazegraph"
    $log_file = '/var/log/wdqs-blazegraph-deadlock-remediation.log'
    $script_path = '/usr/local/sbin/wdqs-blazegraph-deadlock-check'

    # Empty string when updater_metrics_port is undef (e.g. categories
    # instances that don't use the streaming updater). The script skips
    # the lag check when this is empty.
    $updater_metrics_url = $updater_metrics_port ? {
        undef   => '',
        default => "http://localhost:${updater_metrics_port}/metrics",
    }

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
            # Retry + exponential backoff can take up to ~340s per metric
            # fetch (6 attempts * 5s curl timeout + 310s sleep). Two fetches
            # worst case: ~680s. 900s provides margin.
            # systemd will not start a new timer instance while this one is
            # running (oneshot service) — skipped ticks are harmless.
            max_runtime_seconds  => 900,
            user                 => 'root',
            logging_enabled      => false,
            monitoring_enabled   => false,
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
