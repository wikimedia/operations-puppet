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
    Wmflib::Ensure $ensure = lookup('profile::query_service::blazegraph_deadlock_remediation::ensure', {'default_value' => 'absent'}),
    Integer[1] $threshold = lookup('profile::query_service::blazegraph_deadlock_remediation::threshold', {'default_value' => 1200}),
    Integer[1] $cooldown_seconds = lookup('profile::query_service::blazegraph_deadlock_remediation::cooldown_seconds', {'default_value' => 1800}),
    Integer[1, 59] $check_interval_minutes = lookup('profile::query_service::blazegraph_deadlock_remediation::check_interval_minutes', {'default_value' => 5}),
    String $deploy_name = lookup('profile::query_service::deploy_name'),
    Stdlib::Port $prometheus_agent_port = lookup('profile::query_service::blazegraph_deadlock_remediation::prometheus_agent_port', {'default_value' => 9102}),
    Optional[Stdlib::Port] $updater_metrics_port = lookup('profile::query_service::blazegraph_deadlock_remediation::updater_metrics_port', {'default_value' => 9193}),
    Integer $lag_threshold = lookup('profile::query_service::blazegraph_deadlock_remediation::lag_threshold', {'default_value' => 480}),
    Integer $max_retries = lookup('profile::query_service::blazegraph_deadlock_remediation::max_retries', {'default_value' => 5}),
    Integer $retry_base_delay = lookup('profile::query_service::blazegraph_deadlock_remediation::retry_base_delay', {'default_value' => 10}),
) {
    $service_name = "${deploy_name}-blazegraph"
    $log_file = '/var/log/wdqs-blazegraph-deadlock-remediation.log'
    $cooldown_file = '/var/tmp/blazegraph-auto-restart.stamp'
    $script_path = '/usr/local/sbin/wdqs-blazegraph-deadlock-check'
    $config_path = '/etc/blazegraph/deadlock-check.conf'

    # Empty string when updater_metrics_port is undef (e.g. categories
    # instances that don't use the streaming updater). The script skips
    # the lag check when this is empty.
    $updater_metrics_url = $updater_metrics_port ? {
        undef   => '',
        default => "http://localhost:${updater_metrics_port}/metrics",
    }

    $ensure_file = $ensure ? { 'present' => 'file', default => 'absent' }

    file { '/etc/blazegraph':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { $script_path:
        ensure => $ensure_file,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/profile/query_service/blazegraph-deadlock-check.sh',
    }

    file { $config_path:
        ensure  => $ensure_file,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('profile/query_service/blazegraph-deadlock-check.conf.erb'),
        require => File['/etc/blazegraph'],
    }

    systemd::timer::job { 'wdqs-blazegraph-deadlock-check':
        ensure               => $ensure,
        description          => 'Check for Blazegraph instability and auto-restart if detected (T242453)',
        command              => "${script_path} ${config_path}",
        interval             => {
            'start'    => 'OnCalendar',
            'interval' => "*-*-* *:00/${check_interval_minutes}:00",
        },
        # Retry + exponential backoff can take up to ~340s per metric
        # fetch (6 attempts * 5s curl timeout + 310s sleep). Two fetches
        # worst case: ~680s. 900s provides margin.
        max_runtime_seconds  => 900,
        user                 => 'root',
        logging_enabled      => false,
        monitoring_enabled   => false,
        monitoring_notes_url => 'https://wikitech.wikimedia.org/wiki/Wikidata_Query_Service/Runbook#Blazegraph_deadlock',
        require              => [File[$script_path], File[$config_path]],
    }
}
