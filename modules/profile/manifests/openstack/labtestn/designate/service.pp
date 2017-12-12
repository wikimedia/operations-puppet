class profile::openstack::labtestn::designate::service(
    $version = hiera('profile::openstack::labtestn::version'),
    $designate_host = hiera('profile::openstack::labtestn::designate_host'),
    $nova_controller = hiera('profile::openstack::labtestn::nova_controller'),
    $puppetmaster_hostname = hiera('profile::openstack::labtestn::puppetmaster_hostname'),
    $db_pass = hiera('profile::openstack::labtestn::designate::db_pass'),
    $db_host = hiera('profile::openstack::labtestn::designate::db_host'),
    $domain_id_internal_forward = hiera('profile::openstack::labtestn::designate::domain_id_internal_forward'),
    $domain_id_internal_reverse = hiera('profile::openstack::labtestn::designate::domain_id_internal_reverse'),
    $ldap_user_pass = hiera('profile::openstack::labtestn::ldap_user_pass'),
    $pdns_db_pass = hiera('profile::openstack::labtestn::designate::pdns_db_pass'),
    $db_admin_pass = hiera('profile::openstack::labtestn::designate::db_admin_pass'),
    $primary_pdns = hiera('profile::openstack::labtestn::pdns::host'),
    $secondary_pdns = hiera('profile::openstack::labtestn::pdns::host_secondary'),
    $rabbit_pass = hiera('profile::openstack::labtestn::nova::rabbit_pass'),
    $osm_host = hiera('profile::openstack::labtestn::osm_host'),
    $horizon_host = hiera('profile::openstack::labtestn::horizon_host'),
    ) {

    require ::profile::openstack::labtestn::clientlib
    class{'::profile::openstack::base::designate::service':
        version                    => $version,
        designate_host             => $designate_host,
        db_pass                    => $db_pass,
        db_host                    => $db_host,
        domain_id_internal_forward => $domain_id_internal_forward,
        domain_id_internal_reverse => $domain_id_internal_reverse,
        puppetmaster_hostname      => $puppetmaster_hostname,
        nova_controller            => $nova_controller,
        ldap_user_pass             => $ldap_user_pass,
        pdns_db_pass               => $pdns_db_pass,
        db_admin_pass              => $db_admin_pass,
        primary_pdns               => $primary_pdns,
        secondary_pdns             => $secondary_pdns,
        rabbit_pass                => $rabbit_pass,
        osm_host                   => $osm_host,
        horizon_host               => $horizon_host,
    }
    contain '::profile::openstack::base::designate::service'
}
