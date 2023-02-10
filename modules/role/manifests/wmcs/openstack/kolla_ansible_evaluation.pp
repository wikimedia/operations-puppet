# SPDX-License-Identifier: Apache-2.0
class role::wmcs::openstack::kolla_ansible_evaluation {
    system::role { $name : }

    include profile::wmcs::openstack::kolla_ansible_evaluation
}
