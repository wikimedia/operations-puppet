# SPDX-License-Identifier: Apache-2.0
class profile::prometheus::nic_saturation_exporter (
    Wmflib::Ensure      $ensure           = lookup('profile::prometheus::nic_saturation_exporter::ensure')
) {
    class {'prometheus::nic_saturation_exporter':
        ensure         => $ensure,
        listen_address => $facts['networking']['ip']
    }
}
