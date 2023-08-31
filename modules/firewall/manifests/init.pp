# SPDX-License-Identifier: Apache-2.0
# @summary wrapper class to provide common interface to ferm and nft
# @param provider which firewall provider to use
class firewall (
    Firewall::Provider $provider = 'ferm'
) {
    class { $provider: }  # lint:ignore:wmf_styleguide
}
