class profile::openstack::eqiad1::puppetmaster::frontend(
    Array[OpenStack::ControlNode] $openstack_control_nodes = lookup('profile::openstack::eqiad1::openstack_control_nodes'),
    Array[Stdlib::Fqdn] $designate_hosts = lookup('profile::openstack::eqiad1::designate_hosts'),
    $puppetmasters = lookup('profile::openstack::eqiad1::puppetmaster::servers'),
    $puppetmaster_ca = lookup('profile::openstack::eqiad1::puppetmaster::ca'),
    $puppetmaster_webhostname = lookup('profile::openstack::eqiad1::puppetmaster::web_hostname'),
    $cert_secret_path = lookup('profile::openstack::eqiad1::puppetmaster::cert_secret_path'),
    ) {
    class {'::profile::openstack::base::puppetmaster::frontend':
        openstack_control_nodes  => $openstack_control_nodes,
        designate_hosts          => $designate_hosts,
        puppetmasters            => $puppetmasters,
        puppetmaster_ca          => $puppetmaster_ca,
        puppetmaster_webhostname => $puppetmaster_webhostname,
        cert_secret_path         => $cert_secret_path,
    }
}
