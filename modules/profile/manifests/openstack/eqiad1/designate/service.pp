class profile::openstack::eqiad1::designate::service(
    $version = lookup('profile::openstack::eqiad1::version'),
    Array[OpenStack::ControlNode] $openstack_control_nodes = lookup('profile::openstack::eqiad1::openstack_control_nodes'),
    Stdlib::Fqdn $keystone_fqdn = lookup('profile::openstack::eqiad1::keystone_api_fqdn'),
    $puppetmaster_hostname = lookup('profile::openstack::eqiad1::puppetmaster_hostname'),
    $db_pass = lookup('profile::openstack::eqiad1::designate::db_pass'),
    $db_host = lookup('profile::openstack::eqiad1::designate::db_host'),
    String[1] $domain_id_internal_forward = lookup('profile::openstack::eqiad1::designate::domain_id_internal_forward'),
    String[1] $domain_id_internal_reverse_v4 = lookup('profile::openstack::eqiad1::designate::domain_id_internal_reverse_v4'),
    String[1] $domain_id_internal_reverse_v6 = lookup('profile::openstack::eqiad1::designate::domain_id_internal_reverse_v6'),
    String[1] $enabled_notification_handlers = lookup('profile::openstack::eqiad1::designate::enabled_notification_handlers'),
    String[1] $base_domain_name = lookup('profile::openstack::eqiad1::designate::base_domain_name'),
    $ldap_user_pass = lookup('profile::openstack::eqiad1::designate::ldap_user_pass'),
    $pdns_api_key = lookup('profile::openstack::eqiad1::pdns::api_key'),
    $db_admin_pass = lookup('profile::openstack::eqiad1::designate::db_admin_pass'),
    Array[Profile::Openstack::Pdns::Host] $pdns_hosts = lookup('profile::openstack::eqiad1::pdns::hosts'),
    Array[Stdlib::Fqdn] $rabbitmq_nodes = lookup('profile::openstack::eqiad1::rabbitmq_nodes'),
    $rabbit_pass = lookup('profile::openstack::eqiad1::designate::rabbit_pass'),
    $osm_host = lookup('profile::openstack::eqiad1::osm_host'),
    $region = lookup('profile::openstack::eqiad1::region'),
    Integer $mcrouter_port = lookup('profile::openstack::eqiad1::designate::mcrouter_port'),
    Array[Stdlib::Host] $haproxy_nodes = lookup('profile::openstack::eqiad1::haproxy_nodes'),
) {
    $designate_hosts = $openstack_control_nodes.map |$node| { $node['cloud_private_fqdn'] }

    require ::profile::openstack::eqiad1::clientpackages
    class{'::profile::openstack::base::designate::service':
        version                       => $version,
        designate_hosts               => $designate_hosts,
        keystone_fqdn                 => $keystone_fqdn,
        db_pass                       => $db_pass,
        db_host                       => $db_host,
        domain_id_internal_forward    => $domain_id_internal_forward,
        domain_id_internal_reverse_v4 => $domain_id_internal_reverse_v4,
        domain_id_internal_reverse_v6 => $domain_id_internal_reverse_v6,
        enabled_notification_handlers => $enabled_notification_handlers,
        base_domain_name              => $base_domain_name,
        puppetmaster_hostname         => $puppetmaster_hostname,
        openstack_control_nodes       => $openstack_control_nodes,
        ldap_user_pass                => $ldap_user_pass,
        pdns_api_key                  => $pdns_api_key,
        db_admin_pass                 => $db_admin_pass,
        pdns_hosts                    => $pdns_hosts,
        rabbitmq_nodes                => $rabbitmq_nodes,
        rabbit_pass                   => $rabbit_pass,
        osm_host                      => $osm_host,
        region                        => $region,
        mcrouter_port                 => $mcrouter_port,
        haproxy_nodes                 => $haproxy_nodes,
    }

    $run_dnsleaks = $openstack_control_nodes[1]['host_fqdn'] == $facts['networking']['fqdn']

    prometheus::node_textfile { 'wmcs-dnsleaks':
        ensure     => stdlib::ensure($run_dnsleaks),
        filesource => "puppet:///modules/openstack/${version}/admin_scripts/wmcs-dnsleaks.py",
        interval   => '*:12/30',
        run_cmd    => '/usr/local/bin/wmcs-dnsleaks --to-prometheus --deployment eqiad1 --doublecheck',
    }

    if !$run_dnsleaks {
        file { '/var/lib/prometheus/node.d/designateleaks.prom':
            ensure => absent,
        }
    }
}
