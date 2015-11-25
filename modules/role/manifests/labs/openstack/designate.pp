class role::labs::openstack::designate::server {

    system::role { $name: }

    include openstack
    $keystone_host   = hiera('labs_keystone_host')
    $nova_controller = hiera('labs_nova_controller')

    $keystoneconfig  = hiera_hash('keystoneconfig', {})
    $designateconfig = hiera_hash('designateconfig', {})

    $wikitech_ip   = ipresolve('wikitech.wikimedia.org',4)
    $horizon_ip    = ipresolve('horizon.wikimedia.org',4)
    $controller_ip = ipresolve($nova_controller,4)

    $designateconfig['auth_uri']               = "http://${nova_controller}:5000"
    $designateconfig['keystone_auth_host']     = ipresolve($keystone_host,4)
    $designateconfig['keystone_auth_port']     = $keystoneconfig['auth_port']
    $designateconfig['keystone_admin_token']   = $keystoneconfig['admin_token']
    $designateconfig['keystone_auth_protocol'] = $keystoneconfig['auth_protocol']

    class { 'openstack::designate::service':
        keystoneconfig => $keystoneconfig,
        designateconfig => $designateconfig,
    }

    # Poke a firewall hole for the designate api
    ferm::rule { 'designate-api':
        rule => "saddr (${wikitech_ip} ${horizon_ip} ${controller_ip}) proto tcp dport (9001) ACCEPT;",
    }

    file { '/var/lib/designate/.ssh/':
        ensure => directory,
        owner  => 'designate',
        group  => 'designate',
    }

    file { '/var/lib/designate/.ssh/id_rsa':
            owner  => 'designate',
            group  => 'designate',
            mode   => '0400',
            content => secret('ssh/puppet_cert_manager/cert_manager')
    }
}
