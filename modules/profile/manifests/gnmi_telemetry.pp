# SPDX-License-Identifier: Apache-2.0
# == Class profile::gnmi_telemetry
# Sets up network device telemetry collection using gNMI
class profile::gnmi_telemetry (
    Hash[String[3], Netbox::Device::Network] $infra_devices = lookup('profile::netbox::data::network_devices'),
    Hash[String, Stdlib::Port] $ports                       = lookup('profile::gnmi_telemetry::ports'),
    Hash[String, Array[String]] $site_mapping               = lookup('profile::gnmi_telemetry::site_mapping'),
    String $username                                        = lookup('profile::gnmi_telemetry::username'),
    String $password                                        = lookup('profile::gnmi_telemetry::password'),
    Hash[String, Any] $targets_sub                          = lookup('profile::gnmi_telemetry::targets_sub'),
    Hash[String, Any] $outputs                              = lookup('profile::gnmi_telemetry::outputs'),
    Hash[String, Any] $subscriptions                        = lookup('profile::gnmi_telemetry::subscriptions'),
    Hash[String, Any] $processors                           = lookup('profile::gnmi_telemetry::processors'),
) {
    include profile::netops::netdev_intermediate_ca
    $bundle_path = $profile::netops::netdev_intermediate_ca::bundle_path

    $local_sites = $site_mapping[$::site]

    $targets = Hash($infra_devices.filter |$device, $attributes| {
        # must match the filter in modules/netops/manifests/prometheus/grpc.pp to monitor what we collect
        $attributes['site'] in $local_sites and
        $attributes['role'] in ['asw', 'cr', 'cloudsw', 'pfw'] and
        $device !~ /^(asw2)/  # Virtual chassis, to be removed once T418012 is done.
    }.values.map |$device| {
        ["${device['primary_fqdn']}:${ports[$device['manufacturer']]}",
        {'subscriptions' => $targets_sub[$device['manufacturer']]}]
    })

    # Poor man's clustering, split the targets between all local netflow hosts
    # Ensure to add FQDN of the current host also the first time the profile is applied
    $netflow_hosts = (wmflib::resource::hosts('Class', [$::site], 'Profile::Gnmi_telemetry') << $facts['networking']['fqdn']).sort.unique
    $targets_keys = $targets.keys
    $gnmic_targets = $targets.filter |$fqdn, $config| {
        $targets_keys.index($fqdn) % $netflow_hosts.size == $netflow_hosts.index($facts['networking']['fqdn'])
    }
    $filter_params = ['infra_devices', 'targets_sub', 'ports', 'site_mapping']
    class { 'gnmic':
        targets => $gnmic_targets,
        tls_ca  => $bundle_path,
        *       => wmflib::resource::filter_params($filter_params)
    }
}
