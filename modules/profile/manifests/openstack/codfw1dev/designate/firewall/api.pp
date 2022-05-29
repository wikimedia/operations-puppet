class profile::openstack::codfw1dev::designate::firewall::api(
    Array[Stdlib::Fqdn] $labweb_hosts = lookup('profile::openstack::codfw1dev::labweb_hosts'),
    Array[Stdlib::Fqdn] $openstack_controllers = lookup('profile::openstack::codfw1dev::openstack_controllers'),
) {
    class {'profile::openstack::base::designate::firewall::api':
        labweb_hosts          => $labweb_hosts,
        openstack_controllers => $openstack_controllers,
    }
}
