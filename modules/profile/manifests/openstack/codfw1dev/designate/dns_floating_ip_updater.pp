# SPDX-License-Identifier: Apache-2.0
class profile::openstack::codfw1dev::designate::dns_floating_ip_updater (
    Array[OpenStack::ControlNode] $openstack_control_nodes = lookup('profile::openstack::codfw1dev::openstack_control_nodes'),
    String[1]                     $project_zone_template   = lookup('profile::openstack::codfw1dev::designate::dns_floating_ip_updater::project_zone_template'),
    String[1]                     $reverse_zone_project    = lookup('profile::openstack::codfw1dev::designate::dns_floating_ip_updater::reverse_zone_project'),
) {
    class { '::profile::openstack::base::designate::dns_floating_ip_updater':
        openstack_control_nodes => $openstack_control_nodes,
        project_zone_template   => $project_zone_template,
        reverse_zone_project    => $reverse_zone_project,
    }
}
