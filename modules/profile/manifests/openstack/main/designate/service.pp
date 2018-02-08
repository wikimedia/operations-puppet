class profile::openstack::main::designate::service(
    $version = hiera('profile::openstack::main::version'),
    $designate_host = hiera('profile::openstack::main::designate_host'),
    $nova_controller = hiera('profile::openstack::main::nova_controller'),
    $puppetmaster_hostname = hiera('profile::openstack::main::puppetmaster_hostname'),
    $db_pass = hiera('profile::openstack::main::designate::db_pass'),
    $db_host = hiera('profile::openstack::main::designate::db_host'),
    $domain_id_internal_forward = hiera('profile::openstack::main::designate::domain_id_internal_forward'),
    $domain_id_internal_reverse = hiera('profile::openstack::main::designate::domain_id_internal_reverse'),
    $ldap_user_pass = hiera('profile::openstack::main::ldap_user_pass'),
    $pdns_db_pass = hiera('profile::openstack::main::designate::pdns_db_pass'),
    $db_admin_pass = hiera('profile::openstack::main::designate::db_admin_pass'),
    $primary_pdns = hiera('profile::openstack::main::pdns::host'),
    $secondary_pdns = hiera('profile::openstack::main::pdns::host_secondary'),
    $rabbit_pass = hiera('profile::openstack::main::nova::rabbit_pass'),
    $osm_host = hiera('profile::openstack::main::osm_host'),
    $horizon_host = hiera('profile::openstack::main::horizon_host'),
    $labweb_hosts = hiera('profile::openstack::main::labweb_hosts'),
    ) {

    require ::profile::openstack::main::clientlib
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


    class {'::openstack::designate::monitor':
        active => ($::fqdn == $designate_host),
    }
}
