# SPDX-License-Identifier: Apache-2.0
# == Define: prometheus::pdu_config_netbox
#
# Generate prometheus targets configuration for all PDUs in a given site (through netbox-hiera).

# == Parameters
# $dest: The output file where to write the result.
# $pdus: netbox-hiera profile::netbox::data::pdus
# $name_matcher: Regex applied to fqdn to refine the search results
# $model_matcher: Regex applied to model to refine the search results
# $manufacturer: Manufacturer name to refine the search results
# $labels:  Labels to attach to every target. 'row' will be added from
# discovered resources.

define prometheus::pdu_config_netbox(
    String $dest,
    Hash[String[3], Netbox::Device::PDU] $pdus,
    String $name_matcher,
    String $model_matcher,
    String $manufacturer,
    Hash   $labels       = {},
) {

    $pdus_filtered = $pdus.filter |$pdu, $config| {
            ($config['location']['site'] == $::site)
            and
            ($config['manufacturer'] == $manufacturer)
            and
            (!empty(match($pdu, $name_matcher)))
            and
            (!empty(match($config['model'], $model_matcher)))
    }

    $pdu_resources = $pdus_filtered.map |$pdu, $config| {
        {
            'title'      => $pdu,
            'parameters' => {
                'site' => $config['location']['site'],
                'row'  => $config['location']['row'],
            }
        }

    }

    file { $dest:
        ensure  => present,
        mode    => '0444',
        content => template('prometheus/pdu_config.erb'),
    }
}
