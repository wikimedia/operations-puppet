class profile::openstack::labtest::designate::service(
    $version = hiera('profile::openstack::labtest::version'),
    $designate_host = hiera('profile::openstack::labtest::designate_host'),
    $nova_controller = hiera('profile::openstack::labtest::nova_controller'),
    $puppetmaster_hostname = hiera('profile::openstack::labtest::puppetmaster_hostname'),
    $db_pass = hiera('profile::openstack::labtest::designate::db_pass'),
    $db_host = hiera('profile::openstack::labtest::designate::db_host'),
    $domain_id_internal_forward = hiera('profile::openstack::labtest::designate::domain_id_internal_forward'),
    $domain_id_internal_reverse = hiera('profile::openstack::labtest::designate::domain_id_internal_reverse'),
    $ldap_user_pass = hiera('profile::openstack::labtest::ldap_user_pass'),
    $pdns_db_pass = hiera('profile::openstack::labtest::designate::pdns_db_pass'),
    $db_admin_pass = hiera('profile::openstack::labtest::designate::db_admin_pass'),
    $primary_pdns = hiera('profile::openstack::labtest::pdns::host'),
    $secondary_pdns = hiera('profile::openstack::labtest::pdns::host_secondary'),
    $rabbit_pass = hiera('profile::openstack::labtest::nova::rabbit_pass'),
    $osm_host = hiera('profile::openstack::labtest::osm_host'),
    $horizon_host = hiera('profile::openstack::labtest::horizon_host'),
    $labweb_hosts = hiera('profile::openstack::labtest::labweb_hosts'),
    ) {

    require ::profile::openstack::labtest::clientlib
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
        labweb_hosts               => $labweb_hosts,
    }
    contain '::profile::openstack::base::designate::service'
}
