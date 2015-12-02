class role::labs::openstack::designate::server {

    system::role { $name: }

    include openstack

    $keystone_host   = hiera('labs_keystone_host')
    $nova_controller = hiera('labs_nova_controller')
    $designate_host  = hiera('labs_designate_hostname')

    $keystoneconfig  = hiera_hash('keystoneconfig', {})
    $designateconfig = hiera_hash('designateconfig', {})

    $controller_ip   = ipresolve($nova_controller,4)
    $horizon_ip      = ipresolve('horizon.wikimedia.org',4)
    $wikitech_ip     = ipresolve('wikitech.wikimedia.org',4)

    class { 'openstack::designate::service':
        active_server   => $designate_host,
        nova_controller => $nova_controller,
        keystone_host   => $keystone_host,
        keystoneconfig  => $keystoneconfig,
        designateconfig => $designateconfig,
    }

    # Poke a firewall hole for the designate api
    ferm::rule { 'designate-api':
        rule => "saddr (${wikitech_ip} ${horizon_ip} ${controller_ip}) proto tcp dport (9001) ACCEPT;",
    }
}
