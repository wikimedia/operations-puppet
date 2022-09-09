# SPDX-License-Identifier: Apache-2.0
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
    Array[Turnilo::Druid_cluster] $druid_clusters     = lookup('profile::druid::turnilo::druid_clusters'),
    Stdlib::Port                  $port               = lookup('profile::druid::turnilo::port'),
    Boolean                       $monitoring_enabled = lookup('profile::druid::turnilo::monitoring_enabled'),
    String                        $contact_group      = lookup('profile::druid::turnilo::contact_group'),
) {
    # Abuse the fact that we all ready have network device mappings in puppetdb via the netop::check
    # resource with bgp => true matching routers and filter out fw's with bfd => false
    # TODO: pull this data from netbox/puppet integration - T229397
    $network_devices = query_resources(false, 'Netops::Check[~".*"]{bgp=true and bfd=true}', false)
    $export_names_map = Hash($network_devices.map |$device| {
        [$device['parameters']['ipv4'], $device['title']]
    }.sort)
    class { 'turnilo':
        druid_clusters   => $druid_clusters,
        export_names_map => $export_names_map,
    }

    if $monitoring_enabled {
        monitoring::service { 'turnilo':
            description   => 'Check Turnilo node appserver',
            check_command => "check_http_on_port!${port}",
            contact_group => $contact_group,
            notes_url     => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Turnilo-Pivot',
        }
    }
}
