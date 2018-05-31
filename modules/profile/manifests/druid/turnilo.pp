# Class: profile::druid::turnilo
#
# Install and configure the Druid's Turnilo nodejs UI
#
# [*druid_clusters*]
#
# [*port*]
#   The port used by Turnilo to accept HTTP connections.
#   Default: 9091
#
# [*monitoring_enabled*]
#   Enable monitoring for the Turnilo service.
#   Default: false
#
# [*contact_group*]
#   Monitoring's contact grup.
#   Default: 'analytics'
#
class profile::druid::turnilo(
    $druid_clusters     = hiera('profile::druid::turnilo::druid_clusters'),
    $port               = hiera('profile::druid::turnilo::port', 9091),
    $monitoring_enabled = hiera('profile::druid::turnilo::monitoring_enabled', false),
    $contact_group      = hiera('profile::druid::turnilo::contact_group', 'analytics'),
) {
    class { 'turnilo':
        druid_clusters => $druid_clusters,
    }

    monitoring::service { 'turnilo':
        description   => 'turnilo',
        check_command => "check_tcp!${port}",
        contact_group => $contact_group,
    }
}
