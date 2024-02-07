# SPDX-License-Identifier: Apache-2.0
class profile::openstack::base::designate::dns_floating_ip_updater(
    Array[OpenStack::ControlNode] $openstack_control_nodes = lookup('profile::openstack::base::openstack_control_nodes'),
    String[1]                     $project_zone_template   = lookup('profile::openstack::base::designate::dns_floating_ip_updater::project_zone_template'),
    String[1]                     $reverse_zone_project    = lookup('profile::openstack::base::designate::dns_floating_ip_updater::reverse_zone_project'),
) {
    # only run the cronjob in one node
    if $::facts['networking']['fqdn'] == $openstack_control_nodes[0]['host_fqdn'] {
        $ensure = 'present'
    }
    else {
        $ensure = 'absent'
    }

    class { '::openstack::designate::dns_floating_ip_updater':
        ensure                => $ensure,
        project_zone_template => $project_zone_template,
        reverse_zone_project  => $reverse_zone_project,
    }
}
