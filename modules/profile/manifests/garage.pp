# SPDX-License-Identifier: Apache-2.0
# Garage profile, to install and configure a generic Garage instance for WMF Production
# Parameters:
# [*config*]
#  Garage daemon configuration in a single hash. See modules/garage/templates/garage.toml.erb
#  for possible values.
#  See https://garagehq.deuxfleurs.fr/documentation/ for what they do.

class profile::garage(
    Hash $config = lookup('profile::garage::config'),
) {
    class { 'garage':
        config => $config,
    }
}
