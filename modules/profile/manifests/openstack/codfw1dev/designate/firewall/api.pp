class profile::openstack::codfw1dev::designate::firewall::api(
    Array[Stdlib::Fqdn] $labweb_hosts = lookup('profile::openstack::codfw1dev::labweb_hosts'),
    Stdlib::Fqdn $nova_controller = lookup('profile::openstack::codfw1dev::nova_controller'),
    Stdlib::Fqdn $nova_controller_standby = lookup('profile::openstack::codfw1dev::nova_controller'),
    Stdlib::Fqdn $osm_host = lookup('profile::openstack::codfw1dev::osm_host'),
) {
    class {'profile::openstack::base::designate::firewall::api':
        labweb_hosts            => $labweb_hosts,
        nova_controller         => $nova_controller,
        nova_controller_standby => $nova_controller_standby,
        osm_host                => $osm_host,
    }
}
