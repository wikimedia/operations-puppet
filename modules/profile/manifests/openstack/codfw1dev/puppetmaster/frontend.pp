# SPDX-License-Identifier: Apache-2.0
class profile::openstack::codfw1dev::puppetmaster::frontend(
    Array[OpenStack::ControlNode] $openstack_control_nodes = lookup('profile::openstack::codfw1dev::openstack_control_nodes'),
    Array[Stdlib::Fqdn] $designate_hosts = lookup('profile::openstack::codfw1dev::designate_hosts'),
    $puppetmasters = lookup('profile::openstack::codfw1dev::puppetmaster::servers'),
    $puppetmaster_ca = lookup('profile::openstack::codfw1dev::puppetmaster::ca'),
    $puppetmaster_webhostname = lookup('profile::openstack::codfw1dev::puppetmaster::web_hostname'),
    $cert_secret_path = lookup('profile::openstack::codfw1dev::puppetmaster::cert_secret_path'),
    ) {

    # until we dismantle labtestpuppetmaster we need some realm checking here to set this up on a VM
    if ( $::realm != 'labs' ) {
        require ::profile::openstack::codfw1dev::clientpackages
    }

    class {'::profile::openstack::base::puppetmaster::frontend':
        openstack_control_nodes  => $openstack_control_nodes,
        designate_hosts          => $designate_hosts,
        puppetmasters            => $puppetmasters,
        puppetmaster_ca          => $puppetmaster_ca,
        puppetmaster_webhostname => $puppetmaster_webhostname,
        cert_secret_path         => $cert_secret_path,
    }
}
