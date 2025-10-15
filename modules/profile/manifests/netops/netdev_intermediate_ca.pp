# SPDX-License-Identifier: Apache-2.0
# == Class profile::network_devices_int_ca
# Adds the network_devices intermediate CA to system trusted certs
class profile::netops::netdev_intermediate_ca (
) {
    include profile::base::certificates

    $network_devices_ca_path = '/usr/local/share/ca-certificates/network_devices.pem'
    $bundle_path             = '/usr/local/share/ca-certificates/network_devices_bundle.crt'

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
        notify  => Exec['update-ca-certificates'],
    }

}
