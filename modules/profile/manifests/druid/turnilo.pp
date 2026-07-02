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
# [*network_devices*]
#   Map of network devices.
#   Default: Exported from Netbox.
#
class profile::druid::turnilo(
    Array[Turnilo::Druid_cluster]            $druid_clusters     = lookup('profile::druid::turnilo::druid_clusters'),
    Stdlib::Port                             $port               = lookup('profile::druid::turnilo::port'),
    Boolean                                  $monitoring_enabled = lookup('profile::druid::turnilo::monitoring_enabled'),
    Hash[String[3], Netbox::Device::Network] $network_devices    = lookup('profile::netbox::data::network_devices'),
) {

    $network_devices_filtered = $network_devices.filter |$device, $attributes| { $attributes['role'] in ['cr','asw', 'cloudsw', 'pfw'] }
    $export_names_map = Hash($network_devices_filtered.map |$device, $attributes| {
        [$attributes['ipv4'], $device]
    }.sort)

    class { 'turnilo':
        druid_clusters   => $druid_clusters,
        export_names_map => $export_names_map,
    }

    if $monitoring_enabled {
        prometheus::blackbox::check::http { 'turnilo.wikimedia.org':
            port          => $port,
            team          => 'data-engineering',
            probe_runbook => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Turnilo-Pivot',
        }
    }
}
