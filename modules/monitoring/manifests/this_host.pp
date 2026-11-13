# SPDX-License-Identifier: Apache-2.0
# @summary Creates the Icinga host object for this host
class monitoring::this_host () {
    require monitoring
    monitoring::host { $facts['networking']['hostname']:
        critical => $monitoring::host_critical,
    }
}
