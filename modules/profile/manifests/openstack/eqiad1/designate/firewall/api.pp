class profile::openstack::eqiad1::designate::firewall::api(
    Array[Stdlib::Fqdn] $labweb_hosts = lookup('profile::openstack::eqiad1::labweb_hosts'),
    Stdlib::Fqdn $nova_controller = lookup('profile::openstack::eqiad1::nova_controller'),
    Stdlib::Fqdn $nova_controller_standby = lookup('profile::openstack::eqiad1::nova_controller_standby'),
    Stdlib::Fqdn $osm_host = lookup('profile::openstack::eqiad1::osm_host'),
) {
    class {'profile::openstack::base::designate::firewall::api':
        labweb_hosts            => $labweb_hosts,
        nova_controller         => $nova_controller,
        nova_controller_standby => $nova_controller_standby,
        osm_host                => $osm_host,
    }
}
