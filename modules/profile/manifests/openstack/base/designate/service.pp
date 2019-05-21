class profile::openstack::base::designate::service(
    $version = hiera('profile::openstack::base::version'),
    $designate_host = hiera('profile::openstack::base::designate_host'),
    $designate_host_standby = hiera('profile::openstack::base::designate_host_standby'),
    $second_region_designate_host = hiera('profile::openstack::base::second_region_designate_host'),
    $second_region_designate_host_standby = hiera('profile::openstack::base::second_region_designate_host_standby'),
    $nova_controller = hiera('profile::openstack::base::nova_controller'),
    $nova_controller_standby = hiera('profile::openstack::base::nova_controller_standby'),
    $keystone_host = hiera('profile::openstack::base::keystone_host'),
    $puppetmaster_hostname = hiera('profile::openstack::base::puppetmaster_hostname'),
    $db_user = hiera('profile::openstack::base::designate::db_user'),
    $db_pass = hiera('profile::openstack::base::designate::db_pass'),
    $db_host = hiera('profile::openstack::base::designate::db_host'),
    $db_name = hiera('profile::openstack::base::designate::db_name'),
    $domain_id_internal_forward = hiera('profile::openstack::base::designate::domain_id_internal_forward'),
    $domain_id_internal_reverse = hiera('profile::openstack::base::designate::domain_id_internal_reverse'),
    $pool_manager_db_name = hiera('profile::openstack::base::designate::pool_manager_db_name'),
    $ldap_user_pass = hiera('profile::openstack::base::ldap_user_pass'),
    $pdns_db_user = hiera('profile::openstack::base::designate::pdns_db_user'),
    $pdns_db_pass = hiera('profile::openstack::base::designate::pdns_db_pass'),
    $pdns_db_name = hiera('profile::openstack::base::designate::pdns_db_name'),
    $db_admin_user = hiera('profile::openstack::base::designate::db_admin_user'),
    $db_admin_pass = hiera('profile::openstack::base::designate::db_admin_pass'),
    $primary_pdns = hiera('profile::openstack::base::designate::host'),
    $secondary_pdns = hiera('profile::openstack::base::designate::host_secondary'),
    $rabbit_user = hiera('profile::openstack::base::nova::rabbit_user'),
    $rabbit_pass = hiera('profile::openstack::base::nova::rabbit_pass'),
    $keystone_public_port = hiera('profile::openstack::base::keystone::public_port'),
    $keystone_auth_port = hiera('profile::openstack::base::keystone::auth_port'),
    $osm_host = hiera('profile::openstack::base::osm_host'),
    $labweb_hosts = hiera('profile::openstack::base::labweb_hosts'),
    $monitoring_host = hiera('profile::openstack::base::monitoring_host'),
    $region = hiera('profile::openstack::base::region'),
    $coordination_host = hiera('profile::openstack::base::designate_host'),
    ) {

    $primary_pdns_ip = ipresolve($primary_pdns,4)
    $secondary_pdns_ip = ipresolve($secondary_pdns,4)

    class{'::openstack::designate::service':
        active                     => ($::fqdn == $designate_host),
        version                    => $version,
        designate_host             => $designate_host,
        keystone_host              => $keystone_host,
        db_user                    => $db_user,
        db_pass                    => $db_pass,
        db_host                    => $db_host,
        db_name                    => $db_name,
        domain_id_internal_forward => $domain_id_internal_forward,
        domain_id_internal_reverse => $domain_id_internal_reverse,
        pool_manager_db_name       => $pool_manager_db_name,
        puppetmaster_hostname      => $puppetmaster_hostname,
        nova_controller            => $nova_controller,
        ldap_user_pass             => $ldap_user_pass,
        pdns_db_user               => $pdns_db_user,
        pdns_db_pass               => $pdns_db_pass,
        pdns_db_name               => $pdns_db_name,
        db_admin_user              => $db_admin_user,
        db_admin_pass              => $db_admin_pass,
        primary_pdns_ip            => $primary_pdns_ip,
        secondary_pdns_ip          => $secondary_pdns_ip,
        rabbit_user                => $rabbit_user,
        rabbit_pass                => $rabbit_pass,
        rabbit_host_primary        => $nova_controller,
        rabbit_host_secondary      => $nova_controller_standby,
        keystone_public_port       => $keystone_public_port,
        keystone_auth_port         => $keystone_auth_port,
        region                     => $region,
        coordination_host          => $coordination_host,
    }
    contain '::openstack::designate::service'

    $labweb_ips = inline_template("@resolve((<%= @labweb_hosts.join(' ') %>))")
    $labweb_ip6s = inline_template("@resolve((<%= @labweb_hosts.join(' ') %>), AAAA)")
    # Open designate API to Labs web UIs and the commandline on labcontrol
    ferm::rule { 'designate-api':
        rule => "saddr (@resolve(${osm_host}) ${labweb_ip6s} @resolve(${keystone_host}) @resolve(${keystone_host}, AAAA)
                       ${labweb_ips} @resolve(${nova_controller}) @resolve(${nova_controller}, AAAA) @resolve(${nova_controller_standby})
                       @resolve(${nova_controller_standby}, AAAA)
                       @resolve(${monitoring_host})  @resolve(${monitoring_host}, AAAA)) proto tcp dport (9001) ACCEPT;",
    }

    # Allow labs instances to hit the designate api.
    #
    # This is not as permissive as it looks; The wmfkeystoneauth
    #  plugin (via the password whitelist) only allows 'novaobserver'
    #  to authenticate from within labs, and the novaobserver is
    #  limited by the designate policy.json to read-only queries.
    include network::constants
    $labs_networks = join($network::constants::labs_networks, ' ')
    ferm::rule { 'designate-api-for-labs':
        rule => "saddr (${labs_networks}) proto tcp dport (9001) ACCEPT;",
    }

    # allow axfr traffic between mdns and pdns on the pdns hosts
    ferm::rule { 'mdns-axfr':
        rule => "saddr (@resolve(${designate_host}) @resolve(${designate_host_standby})
                        @resolve(${designate_host}, AAAA) @resolve(${designate_host_standby}, AAAA)
                        @resolve(${second_region_designate_host}) @resolve(${second_region_designate_host}, AAAA)
                        @resolve(${second_region_designate_host_standby}) @resolve(${second_region_designate_host_standby}, AAAA))
                 proto tcp dport (5354) ACCEPT;",
    }

    ferm::rule { 'mdns-axfr-udp':
        rule => "saddr (@resolve(${designate_host}) @resolve(${designate_host_standby})
                        @resolve(${designate_host}, AAAA) @resolve(${designate_host_standby}, AAAA)
                        @resolve(${second_region_designate_host}) @resolve(${second_region_designate_host}, AAAA)
                        @resolve(${second_region_designate_host_standby}) @resolve(${second_region_designate_host_standby}, AAAA))
                 proto udp dport (5354) ACCEPT;",
    }
}
