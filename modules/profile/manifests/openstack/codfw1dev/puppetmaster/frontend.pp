class profile::openstack::codfw1dev::puppetmaster::frontend(
    Array[Stdlib::Fqdn] $openstack_controllers = lookup('profile::openstack::codfw1dev::openstack_controllers'),
    Array[Stdlib::Fqdn] $designate_hosts = lookup('profile::openstack::codfw1dev::designate_hosts'),
    $puppetmasters = lookup('profile::openstack::codfw1dev::puppetmaster::servers'),
    $puppetmaster_ca = lookup('profile::openstack::codfw1dev::puppetmaster::ca'),
    $puppetmaster_webhostname = lookup('profile::openstack::codfw1dev::puppetmaster::web_hostname'),
    $labweb_hosts = lookup('profile::openstack::codfw1dev::labweb_hosts'),
    $cert_secret_path = lookup('profile::openstack::codfw1dev::puppetmaster::cert_secret_path'),
    ) {

    # until we dismantle labtestpuppetmaster we need some realm checking here to set this up on a VM
    if ( $::realm != 'labs' ) {
        require ::profile::openstack::codfw1dev::clientpackages
    }

    class {'::profile::openstack::base::puppetmaster::frontend':
        openstack_controllers    => $openstack_controllers,
        designate_hosts          => $designate_hosts,
        puppetmasters            => $puppetmasters,
        puppetmaster_ca          => $puppetmaster_ca,
        puppetmaster_webhostname => $puppetmaster_webhostname,
        labweb_hosts             => $labweb_hosts,
        cert_secret_path         => $cert_secret_path,
    }
}
