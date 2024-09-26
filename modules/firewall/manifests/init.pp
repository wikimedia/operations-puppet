# SPDX-License-Identifier: Apache-2.0
# @summary wrapper class to provide common interface to ferm and nftables
# @param provider which firewall provider to use
class firewall (
    Firewall::Provider $provider = 'none',
) {
    unless $provider == 'none' {
        class { 'ferm': # lint:ignore:wmf_styleguide
            ensure              => stdlib::ensure($provider == 'ferm'),
        }

        # There is currently no Puppet-driven migration path ferm->nft,
        # so always pass ensure=>present if the nftables provider is selected
        if $provider == 'nftables' {
            class { '::nftables': # lint:ignore:wmf_styleguide
                ensure => 'present',
            }
        }
    }
}
