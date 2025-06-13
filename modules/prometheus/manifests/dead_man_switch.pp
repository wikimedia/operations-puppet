# SPDX-License-Identifier: Apache-2.0

# Prometheus Dead Man Switch for meta-monitoring
# https://training.promlabs.com/training/monitoring-and-debugging-prometheus/metrics-based-meta-monitoring/end-to-end-watchdog-alerts/
#
# @param instance Prometheus instance to deploy to
define prometheus::dead_man_switch(
    String                    $instance,
) {
    prometheus::alert::rule { "DeadManSwitch_${instance}":
        alert_name  => 'DeadManSwitch',
        instance    => $instance,
        summary     => 'Dead Man Switch',
        description => 'This is an alert meant to ensure that the entire alerting pipeline is functional. This alert is always firing, therefore it should always be firing in Alertmanager and always fire against a receiver.',
        team        => 'o11y',
        expr        => 'vector(1) > 0',
        for         => '1m',
        group       => 'metamonitoring',
        severity    => 'info',
    }
}
