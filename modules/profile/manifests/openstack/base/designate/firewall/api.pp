class profile::openstack::base::designate::firewall::api(
    Array[Stdlib::Fqdn] $labweb_hosts = lookup('profile::openstack::base::labweb_hosts'),
    Array[Stdlib::Fqdn] $openstack_controllers = lookup('profile::openstack::base::openstack_controllers'),
) {
    ferm::service { 'designate-tls-api':
        proto => 'tcp',
        port  => '29001',
    }
}
