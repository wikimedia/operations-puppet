class profile::openstack::eqiad1::pdns::auth::service(
    Array[Profile::Openstack::Pdns::Host] $hosts = lookup('profile::openstack::eqiad1::pdns::hosts'),
    Array[OpenStack::ControlNode] $openstack_control_nodes = lookup('profile::openstack::eqiad1::openstack_control_nodes'),
    $db_pass = lookup('profile::openstack::eqiad1::pdns::db_pass'),
    String $pdns_api_key = lookup('profile::openstack::eqiad1::pdns::api_key'),
    ) {

    $designate_hosts = $openstack_control_nodes.map |$node| { $node['cloud_private_fqdn'] }

    # We're patching in our ipv4 address for db_host here;
    #  for unclear reasons 'localhost' doesn't work properly
    #  with the version of Mariadb installed on Jessie.
    class {'::profile::openstack::base::pdns::auth::service':
        hosts           => $hosts,
        designate_hosts => $designate_hosts,
        db_pass         => $db_pass,
        db_host         => ipresolve($facts['networking']['fqdn'],4),
        pdns_api_key    => $pdns_api_key,
    }
}
