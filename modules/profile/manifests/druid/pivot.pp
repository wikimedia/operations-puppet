# Class: profile::druid::pivot
#
# Install and configure the Druid's Pivot nodejs UI
#
# [*druid_broker*]
#   The fully qualified domain name (like druid1001.eqiad.wmnet)
#   of the Druid Broker that the Pivot UI will contact.
#
# [*port*]
#   The port used by Pivot to accept HTTP connections.
#   Default: 9090
#
# [*monitoring_enabled*]
#   Enable monitoring for the Pivot service.
#   Default: false
#
# [*contact_group*]
#   Monitoring's contact grup.
#   Default: 'analytics'
#
class profile::druid::pivot(
    $druid_broker       = hiera('profile::druid::pivot::druid_broker'),
    $port               = hiera('profile::druid::pivot::port',9090),
    $monitoring_enabled = hiera('profile::druid::pivot::monitoring_enabled', false),
    $contact_group      = hiera('profile::druid::pivot::contact_group', 'analytics'),
) {
    class { 'pivot':
        druid_broker => $druid_broker,
    }

    monitoring::service { 'pivot':
        description   => 'pivot',
        check_command => "check_tcp!${port}",
        contact_group => $contact_group,
    }
}