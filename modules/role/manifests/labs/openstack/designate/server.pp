class role::labs::openstack::designate::server {

    system::role { $name: }

    include openstack

    $keystone_host   = hiera('labs_keystone_host')
    $nova_controller = hiera('labs_nova_controller')
    $designate_host  = hiera('labs_designate_hostname')
    $osm_host        = hiera('labs_osm_host')
    $horizon_host    = hiera('labs_horizon_host')

    $keystoneconfig  = hiera_hash('keystoneconfig', {})
    $designateconfig = hiera_hash('designateconfig', {})

    $controller_ip   = ipresolve($nova_controller,4)
    $horizon_ip      = ipresolve($horizon_host,4)
    $wikitech_ip     = ipresolve($osm_host,4)

    $dnsconfig             = hiera_hash('labsdnsconfig', {})
    $dns_host              = $dnsconfig['host']
    $dns_host_secondary    = $dnsconfig['host_secondary']
    $dns_host_ip           = ipresolve ($dns_host)
    $dns_host_secondary_ip = ipresolve ($dns_host_secondary)

    class { 'openstack::designate::service':
        active_server     => $designate_host,
        nova_controller   => $nova_controller,
        keystone_host     => $keystone_host,
        keystoneconfig    => $keystoneconfig,
        designateconfig   => $designateconfig,
        primary_pdns_ip   => $dns_host_ip,
        secondary_pdns_ip => $dns_host_secondary_ip,
    }

    # Poke a firewall hole for the designate api
    ferm::rule { 'designate-api':
        rule => "saddr (${wikitech_ip} ${horizon_ip} ${controller_ip}) proto tcp dport (9001) ACCEPT;",
    }

    # allow axfr traffic between mdns and pdns on the pdns hosts
    ferm::rule { 'mdns-axfr':
        rule => "saddr (${dns_host_ip} ${dns_host_secondary_ip} ) proto tcp dport (5354) ACCEPT;",
    }
    ferm::rule { 'mdns-axfr-udp':
        rule => "saddr (${dns_host_ip} ${dns_host_secondary_ip} ) proto udp dport (5354) ACCEPT;",
    }
}
