# == Define: monitoring::grafana_alert
#
# Provisions an Icinga check that "forwards" Grafana alerts
# for a given dashboard.
#
# === Parameters
#
# [*metric*]
#   Grafana dashboard uri. For example: 'db/webpagetest-alerts'.
#   Defaults to the resource title.
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
#  # Emit a critical if any grafana alert on the db/webpagetest-alerts
#  # dashboard is in "alterting" state.
#  monitoring::grafana_alert { 'db/webpagetest-alerts':
#    contact_group  => 'performance',
#  }
#
define monitoring::grafana_alert(
    $dashboard     = $title,
    $ensure        = present,
    $grafana_url   = 'https://grafana.wikimedia.org',
    $contact_group = 'admins'
) {
    monitoring::service { $title:
        ensure        => $ensure,
        description   => "${title} grafana alert",
        check_command => "check_grafana_alert!${title}!${grafana_url}",
        contact_group => $contact_group,
    }
}
