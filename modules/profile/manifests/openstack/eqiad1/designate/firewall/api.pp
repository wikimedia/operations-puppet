class profile::openstack::eqiad1::designate::firewall::api(
    Array[Stdlib::Fqdn] $labweb_hosts = lookup('profile::openstack::eqiad1::labweb_hosts'),
    Array[Stdlib::Fqdn] $openstack_controllers = lookup('profile::openstack::eqiad1::openstack_controllers'),
    Stdlib::Fqdn $osm_host = lookup('profile::openstack::eqiad1::osm_host'),
) {
    class {'profile::openstack::base::designate::firewall::api':
        labweb_hosts          => $labweb_hosts,
        openstack_controllers => $openstack_controllers,
        osm_host              => $osm_host,
    }
}
