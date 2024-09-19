# SPDX-License-Identifier: Apache-2.0
# == Class profile::gnmi_telemetry
# Sets up network device telemetry collection using gNMI
class profile::gnmi_telemetry (
    Hash[String[3], Netbox::Device::Network] $infra_devices = lookup('profile::netbox::data::network_devices'),
    Hash[String, Stdlib::Port] $ports                       = lookup('profile::gnmi_telemetry::ports'),
    String $username                                        = lookup('profile::gnmi_telemetry::username'),
    String $password                                        = lookup('profile::gnmi_telemetry::password'),
    Hash[String, Any] $targets_sub                          = lookup('profile::gnmi_telemetry::targets_sub'),
    Hash[String, Any] $outputs                              = lookup('profile::gnmi_telemetry::outputs'),
    Hash[String, Any] $subscriptions                        = lookup('profile::gnmi_telemetry::subscriptions'),
    Hash[String, Any] $processors                           = lookup('profile::gnmi_telemetry::processors'),
) {
    include profile::base::certificates

    $bundle_path             = '/etc/ssl/localcerts/network_devices_bundle.pem'
    $network_devices_ca_path = '/etc/ssl/localcerts/network_devices.pem'
    file { $network_devices_ca_path:
        ensure => file,
        source => 'http://pki.discovery.wmnet/bundles/network_devices.pem',
    }
    $command = @("COMMAND"/L$)
    /bin/cat ${network_devices_ca_path} \
        ${profile::base::certificates::trusted_certs['bundle']} \
        > ${bundle_path}
    |- COMMAND
    $unless = @("UNLESS"/L$)
    /usr/bin/test \
        "$(/usr/bin/sha256sum ${bundle_path}| awk '{print \$1}')" \
        = \
        "$(/bin/cat ${network_devices_ca_path} \
            ${profile::base::certificates::trusted_certs['bundle']} \
            | /usr/bin/sha256sum | awk '{print \$1}')"
    |- UNLESS
    exec { 'generate network device bundle':
        command => $command,
        unless  => $unless,
        require => File[$network_devices_ca_path],
    }

    $targets = Hash($infra_devices.filter |$device, $attributes| {
        $attributes['role'] in ['asw', 'cr', 'cloudsw'] and $attributes['site'] == $::site
    }.values.map |$device| {
        ["${device['primary_fqdn']}:${ports[$device['manufacturer']]}",
        {'subscriptions' => $targets_sub[$device['manufacturer']]}]
    })

    $filter_params = ['infra_devices', 'targets_sub', 'ports']
    class { 'gnmic':
        targets => $targets,
        tls_ca  => $bundle_path,
        *       => wmflib::resource::filter_params($filter_params)
    }
}
