class profile::openstack::eqiad1::pdns::auth::service(
    Array[Hash] $hosts = lookup('profile::openstack::eqiad1::pdns::hosts'),
    Array[OpenStack::ControlNode] $openstack_control_nodes = lookup('profile::openstack::eqiad1::openstack_control_nodes'),
    String $openstack_control_node_interface = lookup('profile::openstack::base::neutron::openstack_control_node_interface', {default_value => 'cloud_private_fqdn'}),
    $db_pass = lookup('profile::openstack::eqiad1::pdns::db_pass'),
    String $pdns_api_key = lookup('profile::openstack::eqiad1::pdns::api_key'),
    Stdlib::Fqdn        $monitor_fqdn           = lookup('profile::openstack::eqiad1::pdns::auth::service::monitor_fqdn'),
    Array[Stdlib::Fqdn] $monitor_verify_records = lookup('profile::openstack::eqiad1::pdns::auth::service::monitor_verify_records'),
    ) {

    $designate_hosts = $openstack_control_nodes.map |$node| { $node[$openstack_control_node_interface] }

    # We're patching in our ipv4 address for db_host here;
    #  for unclear reasons 'localhost' doesn't work properly
    #  with the version of Mariadb installed on Jessie.
    class {'::profile::openstack::base::pdns::auth::service':
        hosts           => $hosts,
        designate_hosts => $designate_hosts,
        db_pass         => $db_pass,
        db_host         => ipresolve($::fqdn,4),
        pdns_api_key    => $pdns_api_key,
    }

    $monitor_verify_records.each | Stdlib::Fqdn $verify_record | {
        monitoring::service { "Auth DNS UDP: ${verify_record} on server ${monitor_fqdn}":
            description   => "Check DNS auth via UDP of ${verify_record} on server ${monitor_fqdn}",
            check_command => "check_dig!${monitor_fqdn}!${verify_record}",
            notes_url     => 'https://wikitech.wikimedia.org/wiki/Portal:Cloud_VPS/Admin/Troubleshooting',
        }

        monitoring::service { "Auth DNS TCP: ${verify_record} on server ${monitor_fqdn}":
            description   => "Check DNS auth via TCP of ${verify_record} on server ${monitor_fqdn}",
            check_command => "check_dig_tcp!${monitor_fqdn}!${verify_record}",
            notes_url     => 'https://wikitech.wikimedia.org/wiki/Portal:Cloud_VPS/Admin/Troubleshooting',
        }
    }
}
