# SPDX-License-Identifier: Apache-2.0

class openstack::neutron::common::epoxy::trixie(
) {
    require openstack::serverpackages::epoxy::trixie

    package { 'neutron-common':
        ensure => 'present',
    }
}
