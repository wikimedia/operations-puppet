# == Define: monitoring::grafana_alert
#
# Provisions an Icinga check that "forwards" Grafana alerts
# for a given dashboard.
#
# === Parameters
#
# [*dashboard_uid*]
#   Grafana dashboard uid. For example: '000000400'.
#   Required.
#
# [*grafana_url*]
#   URL of Grafana.
#   Defaults to 'https://grafana.wikimedia.org'.
#
# [*contact_group*]
#   Icinga contact group that should receive alerts.
#   Defaults to 'admins'.
#
# === Examples
#
#  # Emit a critical if any grafana alert on the jobqueue-eventbus
#  # dashboard is in "alterting" state.
#  monitoring::grafana_alert { 'db/jobqueue-eventbus':
#      dashboard_uid => '000000400',
#  }
#
define monitoring::grafana_alert(
    $dashboard_uid,
    $ensure        = present,
    $grafana_url   = 'https://grafana.wikimedia.org',
    $contact_group = 'admins',
    $notes_url     = undef,
) {
    monitoring::service { $title:
        ensure        => $ensure,
        description   => "${title} grafana alert",
        check_command => "check_grafana_alert!${dashboard_uid}!${grafana_url}",
        contact_group => $contact_group,
        notes_url     => $notes_url,
    }
}
