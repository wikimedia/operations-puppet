# SPDX-License-Identifier: Apache-2.0

class openstack::kolla_ansible_evaluation (
) {
    # only for Cloud VPS VMs:
    requires_realm('labs')

    file { '/usr/local/bin/wmcs-kolla-ansible-evaluation.sh':
        ensure => 'present',
        mode   => '0755',
        source => 'puppet:///modules/openstack/wmcs-kolla-ansible-evaluation.sh',
    }
}
