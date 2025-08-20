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
    String[1]                   $dashboard          = 'TODO',
    String[1]                   $runbook            = 'TODO',
    String[1]                   $logs               = 'TODO',
    String[1]                   $team               = 'sre',
    Prometheus::Alert::Severity $severity           = 'warning',
    Wmflib::Sites               $site               = $::site,  # lint:ignore:top_scope_facts
    Array[String[1]]            $def_label_whitelst = [ 'team', 'severity' ],
    Wmflib::Ensure              $ensure             = present,
) {
    $safe_title = $title.regsubst('\W', '_', 'G')
    $alert_title = "alerts_${instance}_${safe_title}"

    if ($severity == 'page' and $summary !~ /#page/) {
        fail('Paging alerts must contain #page in the summary')
    }

    # Ideally we would validate instance via a type, unfortunately Puppet can
    # not build Enum types dynamically.
    $valid_instances = prometheus::instances().keys
    unless $instance in $valid_instances {
        fail("Invalid Prometheus instance '${instance}'. Must be one of: ${valid_instances.join(', ')}")
    }

    $_alert_config = {
        'alert'  => $alert_name,
        'expr'   => $expr,
        'for'    => $for,
        'annotations' => {
            'description' => $description,
            'summary'     => $summary,
            'dashboard'   => $dashboard,
            'logs'        => $logs,
            'runbook'     => $runbook,
        },
    }

    $def_labels = {
        'team'     => $team,
        'severity' => $severity
    }

    $labels = {
        'labels' => $def_labels.reduce({}) |$memo, $label| {
            if $label[0] in $def_label_whitelst {
                $memo + $label
            } else {
                $memo
            }
        }
    }

    $alert_config = length($labels['labels'].keys) > 0 ? {
        true  => $_alert_config + $labels,
        false => $_alert_config
    }


    $alert_rule_params  = {
        'instance' => $instance,
        'config'   => $alert_config,
        'group'    => $group,
        'tag'      => "prometheus::alert::rule::${site}::${instance}",
    }

    if $ensure == 'present' {
        wmflib::resource::export('prometheus::alert::placeholder', $alert_title, $title, $alert_rule_params)
    }
}
