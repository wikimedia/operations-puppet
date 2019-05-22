class profile::openstack::eqiad1::designate::service(
    $version = hiera('profile::openstack::eqiad1::version'),
    $designate_host = hiera('profile::openstack::eqiad1::designate_host'),
    $designate_host_standby = hiera('profile::openstack::eqiad1::designate_host_standby'),
    $second_region_designate_host = hiera('profile::openstack::eqiad1::second_region_designate_host'),
    $second_region_designate_host_standby = hiera('profile::openstack::eqiad1::second_region_designate_host_standby'),
    $nova_controller = hiera('profile::openstack::eqiad1::nova_controller'),
    $nova_controller_standby = hiera('profile::openstack::eqiad1::nova_controller_standby'),
    $puppetmaster_hostname = hiera('profile::openstack::eqiad1::puppetmaster_hostname'),
    $db_pass = hiera('profile::openstack::eqiad1::designate::db_pass'),
    $db_host = hiera('profile::openstack::eqiad1::designate::db_host'),
    $domain_id_internal_forward = hiera('profile::openstack::eqiad1::designate::domain_id_internal_forward'),
    $domain_id_internal_reverse = hiera('profile::openstack::eqiad1::designate::domain_id_internal_reverse'),
    $ldap_user_pass = hiera('profile::openstack::eqiad1::ldap_user_pass'),
    $pdns_db_pass = hiera('profile::openstack::eqiad1::designate::pdns_db_pass'),
    $db_admin_pass = hiera('profile::openstack::eqiad1::designate::db_admin_pass'),
    $primary_pdns = hiera('profile::openstack::eqiad1::pdns::host'),
    $secondary_pdns = hiera('profile::openstack::eqiad1::pdns::host_secondary'),
    $rabbit_pass = hiera('profile::openstack::eqiad1::nova::rabbit_pass'),
    $osm_host = hiera('profile::openstack::eqiad1::osm_host'),
    $labweb_hosts = hiera('profile::openstack::eqiad1::labweb_hosts'),
    $region = hiera('profile::openstack::eqiad1::region'),
    $coordination_host = hiera('profile::openstack::eqiad1::designate_host'),
) {

    require ::profile::openstack::eqiad1::clientpackages
    class{'::profile::openstack::base::designate::service':
        version                              => $version,
        designate_host                       => $designate_host,
        designate_host_standby               => $designate_host_standby,
        second_region_designate_host         => $second_region_designate_host,
        second_region_designate_host_standby => $second_region_designate_host_standby,
        keystone_host                        => $nova_controller,
        db_pass                              => $db_pass,
        db_host                              => $db_host,
        domain_id_internal_forward           => $domain_id_internal_forward,
        domain_id_internal_reverse           => $domain_id_internal_reverse,
        puppetmaster_hostname                => $puppetmaster_hostname,
        nova_controller                      => $nova_controller,
        nova_controller_standby              => $nova_controller_standby,
        ldap_user_pass                       => $ldap_user_pass,
        pdns_db_pass                         => $pdns_db_pass,
        db_admin_pass                        => $db_admin_pass,
        primary_pdns                         => $primary_pdns,
        secondary_pdns                       => $secondary_pdns,
        rabbit_pass                          => $rabbit_pass,
        osm_host                             => $osm_host,
        labweb_hosts                         => $labweb_hosts,
        region                               => $region,
        coordination_host                    => $coordination_host,
    }

    class {'::openstack::designate::monitor':
        active         => true,
        critical       => true,
        contact_groups => 'wmcs-team',
    }

    # Memcached for coordination between pool managers
    class { '::memcached':
    }

    class { '::profile::prometheus::memcached_exporter': }

    ferm::service { 'designate_memcached':
        proto  => 'tcp',
        port   => '11000',
        srange => "(@resolve(${second_region_designate_host}) @resolve(${second_region_designate_host}, AAAA))"
    }
}
