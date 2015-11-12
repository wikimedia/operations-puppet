class role::labs::openstack::designate::config {
    include openstack
    include passwords::designate
    include passwords::pdns
    include passwords::labs::rabbitmq

    $commondesignateconfig = {
        db_name              => 'designate',
        pool_manager_db_name => 'designate_pool_manager',
        db_user              => $passwords::designate::db_user,
        db_pass              => $passwords::designate::db_pass,
        rabbit_user          => $passwords::labs::rabbitmq::rabbit_userid,
        rabbit_pass          => $passwords::labs::rabbitmq::rabbit_password,
        pdns_db_name         => 'pdns',
        pdns_db_user         => $passwords::pdns::db_user,
        pdns_db_pass         => $passwords::pdns::db_pass,
        pdns_db_admin_user   => $passwords::pdns::db_admin_user,
        pdns_db_admin_pass   => $passwords::pdns::db_admin_pass,
    }
}

class role::labs::openstack::designate::config::eqiad inherits role::labs::openstack::designate::config {
    include role::labs::openstack::keystone::config::eqiad

    $nova_controller = hiera('labs_nova_controller')

    $controller_hostname = $::realm ? {
        'production' => $nova_controller,
        'labs'       => $nova_controller_hostname ? {
            undef   => $::ipaddress_eth0,
            default => $nova_controller_hostname,
        }
    }

    $keystoneconfig = $role::labs::openstack::keystone::config::eqiad::keystoneconfig

    $db_host = $::realm ? {
        'production' => 'm5-master.eqiad.wmnet',
        'labs'       => $::ipaddress_eth0,
    }

    $pdns_db_host = $::realm ? {
        'production' => 'm5-master.eqiad.wmnet',
        'labs'       => $::ipaddress_eth0,
    }

    $auth_uri = $::realm ? {
        'production' => "http://${nova_controller}:5000",
        'labs'       => "http://${::ipaddress_eth0}:5000",
    }

    $eqiaddesignateconfig = {
        db_host                => $db_host,
        pdns_db_host           => $pdns_db_host,
        auth_uri               => $auth_uri,
        rabbit_host            => $controller_hostname,
        controller_hostname    => $controller_hostname,
        keystone_admin_token   => $keystoneconfig['admin_token'],
        keystone_auth_host     => $keystoneconfig['bind_ip'],
        keystone_auth_protocol => $keystoneconfig['auth_protocol'],
        keystone_auth_port     => $keystoneconfig['auth_port'],
        dhcp_domain            => 'eqiad',
    }
    $designateconfig = merge($eqiaddesignateconfig, $commondesignateconfig)
}

class role::labs::openstack::designate::server {
    include role::labs::openstack::designate::config::eqiad

    if $::realm == 'labs' and $::openstack_site_override != undef {
        $designateconfig = $::openstack_site_override ? {
            'eqiad' => $role::labs::openstack::designate::config::eqiad::designateconfig,
        }
    } else {
        $designateconfig = $::site ? {
            'eqiad' => $role::labs::openstack::designate::config::eqiad::designateconfig,
        }
    }

    class { 'openstack::designate::service':
        designateconfig      => $designateconfig,
    }


    # Firewall
    $wikitech = ipresolve('wikitech.wikimedia.org',4)
    $horizon = ipresolve('horizon.wikimedia.org',4)
    $controller = ipresolve(hiera('labs_nova_controller'),4)

    # Poke a firewall hole for the designate api
    ferm::rule { 'designate-api':
        rule => "saddr (${wikitech} ${horizon} ${controller}) proto tcp dport (9001) ACCEPT;",
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
