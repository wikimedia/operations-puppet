# == Define: monitoring::graphite_freshness
#
# Provisions an Icinga check that ensures a Graphite metric is 'fresh':
# that is, continuing to receive updates.
#
# === Parameters
#
# [*metric*]
#   Graphite metric name. For example: 'reqstats.500'.
#   Defaults to the resource title.
#
# [*warning*]
#   Warn if most recent datapoint is older than this value.
#   Value suffix may be one of 's', 'm', 'h' or 'd' for seconds,
#   minutes, hours, or days, respectively.
#
# [*critical*]
#   Crit if most recent datapoint is older than this value.
#   Value suffix may be one of 's', 'm', 'h' or 'd' for seconds,
#   minutes, hours, or days, respectively.
#
# [*graphite_url*]
#   URL of Graphite's render API endpoint.
#   Defaults to 'https://graphite.wikimedia.org/render'.
#
# [*contact_group*]
#   Icinga contact group that should receive alerts.
#   Defaults to 'admins'.
#
# === Examples
#
#  # Emit a warning if most recent datapoint for metric 'reqerror.500'
#  # is older than 5 minutes, and a critical alert if older than 10.
#  monitoring::graphite_freshness { 'reqerror.500':
#    warning  => '5m',
#    critical => '10m',
#  }
#
define monitoring::graphite_freshness(
    $warning,
    $critical,
    $metric        = $title,
    $ensure        = present,
    $graphite_url  = 'https://graphite.wikimedia.org/render',
    $contact_group = 'admins'
) {
    monitoring::service { $title:
        ensure        => $ensure,
        description   => "'${metric}' Graphite freshness",
        check_command => "check_graphite_freshness!${metric}!${graphite_url}!${warning}!${critical}",
        contact_group => $contact_group,
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Graphite#Operations_troubleshooting',
    }
}
