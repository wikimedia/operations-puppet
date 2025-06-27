# SPDX-License-Identifier: Apache-2.0
# @summary manages prometheus metrics for nftables based throttling
class profile::prometheus::nft_throttling_denylist (
        Wmflib::Ensure $ensure = lookup('profile::prometheus::nft_throttling_denylist::ensure',
    {default_value => present}),
) {
    class {'prometheus::nft_throttling_denylist':
        ensure => $ensure,
    }
}
