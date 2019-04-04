# == Define: netops::ripeatlas
#
# Sets up automated RIPE Atlas measurements checks. Tailored towards
# pre-defined measurements for our anchors and not (yet?) a generic measurement
# check.
#
# === Parameters
#
# [*ipv4*]
#   The IPv4 measurement ID.
#
# [*ipv6*]
#   The IPv6 measurement ID.
#
# === Examples
#
#  netops::ripeatlas { 'eqiad':
#      ipv4 => '1790945',
#      ipv6 => '1790947',
#  }

define netops::ripeatlas(
    $ipv4=undef,
    $ipv6=undef,
    $loss_allow=50,
    $failures=35,
    $group='network',
) {
    if $ipv4 {
        monitoring::service { "atlas-ping-${title}-ipv4":
            description    => "IPv4 ping to ${title}",
            check_command  => "check_ripe_atlas!${ipv4}!${loss_allow}!${failures}",
            host           => "ripe-atlas-${title}",
            group          => $group,
            check_interval => 5,
            notes_url      => 'https://wikitech.wikimedia.org/wiki/Network_monitoring#Atlas_alerts',
        }
    }

    if $ipv6 {
        monitoring::service { "atlas-ping-${title}-ipv6":
            description    => "IPv6 ping to ${title}",
            check_command  => "check_ripe_atlas!${ipv6}!${loss_allow}!${failures}",
            host           => "ripe-atlas-${title} IPv6",
            group          => $group,
            check_interval => 5,
            notes_url      => 'https://wikitech.wikimedia.org/wiki/Network_monitoring#Atlas_alerts',
        }
    }
}
