class profile::openstack::eqiad1::designate::service(
    $version = lookup('profile::openstack::eqiad1::version'),
    Array[OpenStack::ControlNode] $openstack_control_nodes = lookup('profile::openstack::eqiad1::openstack_control_nodes'),
    String $openstack_control_node_interface = lookup('profile::openstack::base::neutron::openstack_control_node_interface', {default_value => 'cloud_private_fqdn'}),
    Stdlib::Fqdn $keystone_fqdn = lookup('profile::openstack::eqiad1::keystone_api_fqdn'),
    $puppetmaster_hostname = lookup('profile::openstack::eqiad1::puppetmaster_hostname'),
    $db_pass = lookup('profile::openstack::eqiad1::designate::db_pass'),
    $db_host = lookup('profile::openstack::eqiad1::designate::db_host'),
    $domain_id_internal_forward = lookup('profile::openstack::eqiad1::designate::domain_id_internal_forward'),
    $domain_id_internal_forward_legacy = lookup('profile::openstack::eqiad1::designate::domain_id_internal_forward_legacy'),
    $domain_id_internal_reverse = lookup('profile::openstack::eqiad1::designate::domain_id_internal_reverse'),
    $ldap_user_pass = lookup('profile::openstack::eqiad1::ldap_user_pass'),
    $pdns_api_key = lookup('profile::openstack::eqiad1::pdns::api_key'),
    $db_admin_pass = lookup('profile::openstack::eqiad1::designate::db_admin_pass'),
    Array[Hash] $pdns_hosts = lookup('profile::openstack::eqiad1::pdns::hosts'),
    Array[Stdlib::Fqdn] $rabbitmq_nodes = lookup('profile::openstack::eqiad1::rabbitmq_nodes'),
    $rabbit_pass = lookup('profile::openstack::eqiad1::nova::rabbit_pass'),
    $osm_host = lookup('profile::openstack::eqiad1::osm_host'),
    $region = lookup('profile::openstack::eqiad1::region'),
    Integer $mcrouter_port = lookup('profile::openstack::eqiad1::designate::mcrouter_port'),
    Array[Stdlib::Host] $haproxy_nodes = lookup('profile::openstack::eqiad1::haproxy_nodes'),
    Boolean $enforce_policy_scope = lookup('profile::openstack::eqiad1::keystone::enforce_policy_scope'),
    Boolean $enforce_new_policy_defaults = lookup('profile::openstack::eqiad1::keystone::enforce_new_policy_defaults'),
) {
    $designate_hosts = $openstack_control_nodes.map |$node| { $node[$openstack_control_node_interface] }

    require ::profile::openstack::eqiad1::clientpackages
    class{'::profile::openstack::base::designate::service':
        version                           => $version,
        designate_hosts                   => $designate_hosts,
        keystone_fqdn                     => $keystone_fqdn,
        db_pass                           => $db_pass,
        db_host                           => $db_host,
        domain_id_internal_forward        => $domain_id_internal_forward,
        domain_id_internal_forward_legacy => $domain_id_internal_forward_legacy,
        domain_id_internal_reverse        => $domain_id_internal_reverse,
        puppetmaster_hostname             => $puppetmaster_hostname,
        openstack_control_nodes           => $openstack_control_nodes,
        ldap_user_pass                    => $ldap_user_pass,
        pdns_api_key                      => $pdns_api_key,
        db_admin_pass                     => $db_admin_pass,
        pdns_hosts                        => $pdns_hosts,
        rabbitmq_nodes                    => $rabbitmq_nodes,
        rabbit_pass                       => $rabbit_pass,
        osm_host                          => $osm_host,
        region                            => $region,
        mcrouter_port                     => $mcrouter_port,
        haproxy_nodes                     => $haproxy_nodes,
        enforce_policy_scope              => $enforce_policy_scope,
        enforce_new_policy_defaults       => $enforce_new_policy_defaults,
    }

    prometheus::node_textfile { 'wmcs-dnsleaks':
        filesource => "puppet:///modules/openstack/${version}/admin_scripts/wmcs-dnsleaks.py",
        interval   => '*:0/30',
        run_cmd    => '/usr/local/bin/wmcs-dnsleaks --to-prometheus',
    }
}
