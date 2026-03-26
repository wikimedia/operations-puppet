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
#
# Called from profile::query_service::blazegraph for every instance.

define profile::query_service::blazegraph_deadlock_remediation (
    String $service_name,
    Stdlib::Port $prometheus_agent_port,
    Wmflib::Ensure $ensure = 'present',
    Integer[1] $threshold = 1200,
    Integer[1] $cooldown_seconds = 1800,
    Integer[1, 59] $check_interval_minutes = 5,
    Optional[Stdlib::Port] $updater_metrics_port = undef,
    Integer[1] $lag_threshold = 480,
    Integer[1] $max_retries = 5,
    Integer[1] $retry_base_delay = 10,
) {
    $log_file = '/var/log/wdqs-blazegraph-deadlock-remediation.log'
    $cooldown_file = "/var/tmp/${title}-auto-restart.stamp"
    $script_path = '/usr/local/sbin/wdqs-blazegraph-deadlock-check'
    $config_path = "/etc/blazegraph/${title}-deadlock-check.conf"
    $timer_name = "${title}-deadlock-check"

    # Empty string when updater_metrics_port is undef (e.g. categories
    # instances that don't use the streaming updater). The script skips
    # the lag check when this is empty.
    $updater_metrics_url = $updater_metrics_port ? {
        undef   => '',
        default => "http://localhost:${updater_metrics_port}/metrics",
    }

    $ensure_file = $ensure ? { 'present' => 'file', default => 'absent' }

    # Shared resources: script and /etc/blazegraph directory are used by all
    # instances on a host. Use ensure_resource to avoid duplicate declarations
    # when multiple blazegraph instances coexist (e.g. wikidata + categories).
    ensure_resource('file', '/etc/blazegraph', {
        'ensure' => 'directory',
        'owner'  => 'root',
        'group'  => 'root',
        'mode'   => '0755',
    })

    ensure_resource('file', $script_path, {
        'ensure' => 'file',
        'owner'  => 'root',
        'group'  => 'root',
        'mode'   => '0755',
        'source' => 'puppet:///modules/profile/query_service/blazegraph-deadlock-check.sh',
    })

    file { $config_path:
        ensure  => $ensure_file,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('profile/query_service/blazegraph-deadlock-check.conf.erb'),
        require => File['/etc/blazegraph'],
    }

    systemd::timer::job { $timer_name:
        ensure               => $ensure,
        description          => "Check for Blazegraph instability and auto-restart ${service_name} if detected (T242453)",
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
