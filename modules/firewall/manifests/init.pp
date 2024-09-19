# SPDX-License-Identifier: Apache-2.0
# @summary wrapper class to provide common interface to ferm and nftables
# @param provider which firewall provider to use
class firewall (
    Firewall::Provider $provider = 'none',
    Boolean $ferm_status_restart = false,
) {
    unless $provider == 'none' {
        class { 'ferm': # lint:ignore:wmf_styleguide
            ensure              => stdlib::ensure($provider == 'ferm'),
            ferm_status_restart => $ferm_status_restart,
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
