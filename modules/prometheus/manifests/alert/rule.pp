# SPDX-License-Identifier: Apache-2.0
# @summary resource to configure a Prometheus alerting rule from Puppet. Please note that using alerts.git repository is the preferred way to manage alerts.
# @param alert_name Name for the alert
# @param summary Short alert gist
# @param description Alert full description
# @param expr Alert condition
# @param for The time interval required for an alert condition to trigger an alert
# @param group The group the alert belongs to
# @param dashboard Dashboard url
# @param runbook Runbook url
# @param logs Logs url
# @param team the WMF team to alert
# @param severity The severity of the alert
# @param site Deployment site
# @param instance The prometheus instance to deploy to
define prometheus::alert::rule (
    Prometheus::Alert::Name     $alert_name,
    String[1]                   $instance,
    String[1]                   $summary,
    String[1]                   $description,
    String[1]                   $expr,
    Prometheus::Alert::Duration $for,
    Prometheus::Alert::Group    $group,
    String[1]                   $dashboard = 'TODO',
    String[1]                   $runbook   = 'TODO',
    String[1]                   $logs      = 'TODO',
    String[1]                   $team      = 'sre',
    Prometheus::Alert::Severity $severity  = 'warning',
    Wmflib::Sites               $site      = $::site,  # lint:ignore:top_scope_facts
) {
    $safe_title = $alert_name.regsubst('\W', '_', 'G')
    $alert_title = "alerts_${instance}_${safe_title}_${severity}"

    if ($severity == 'page' and $summary !~ /#page/) {
        fail('Paging alerts must contain #page in the summary')
    }

    # Ideally we would validate instance via a type, unfortunately Puppet can
    # not build Enum types dynamically.
    $valid_instances = prometheus::instances().keys
    unless $instance in $valid_instances {
        fail("Invalid Prometheus instance '${instance}'. Must be one of: ${valid_instances.join(', ')}")
    }

    $alert_config = {
        'alert'  => $alert_name,
        'expr'   => $expr,
        'for'    => $for,
        'labels' => {
            'team'     => $team,
            'severity' => $severity,
        },
        'annotations' => {
            'description' => $description,
            'summary'     => $summary,
            'dashboard'   => $dashboard,
            'logs'        => $logs,
            'runbook'     => $runbook,
        },
    }

    $alert_rule_params  = {
        'instance' => $instance,
        'config'   => $alert_config,
        'group'    => $group,
        'tag'      => "prometheus::alert::rule::${site}::${instance}",
    }

    wmflib::resource::export('prometheus::alert::placeholder', $alert_title, $title, $alert_rule_params)
}
