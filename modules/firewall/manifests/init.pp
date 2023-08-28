# SPDX-License-Identifier: Apache-2.0
# @summary wrapper class to provide common interface to ferm and nftables
# @param provider which firewall provider to use
class firewall (
    Firewall::Provider $provider = 'ferm'
) {
    class { 'ferm':  # lint:ignore:wmf_styleguide
        ensure => stdlib::ensure($provider == 'ferm'),
    }
    class { 'nftables':  # lint:ignore:wmf_styleguide
        ensure => stdlib::ensure($provider == 'nftables'),
    }
}
