class role::designate::config {
    include openstack
    #include passwords::openstack::designate

    $commondesignateconfig = {
        db_name => 'designate',
        db_user => 'designate',
        #db_pass => $passwords::openstack::designate::designate_db_pass,
    }
}

class role::designate::config::eqiad inherits role::designate::config {
    include role::keystone::config::eqiad

    $keystoneconfig = $role::keystone::config::eqiad::keystoneconfig

    $db_host = $::realm ? {
        'production' => 'virt1000.wikimedia.org',
        'labs'       => $::ipaddress_eth0,
    }

    $bind_ip = $::realm ? {
        'production' => '208.80.154.18',
        'labs'       => $::ipaddress_eth0,
    }

    $auth_uri = $::realm ? {
        'production' => 'http://virt1000.wikimedia.org:5000',
        'labs'       => "http://$::ipaddress_eth0:5000",
    }

    $eqiaddesignateconfig = {
        db_host                => $db_host,
        bind_ip                => $bind_ip,
        auth_uri               => $auth_uri,
        keystone_admin_token   => $keystoneconfig['admin_token'],
        keystone_auth_host     => $keystoneconfig['bind_ip'],
        keystone_auth_protocol => $keystoneconfig['auth_protocol'],
        keystone_auth_port     => $keystoneconfig['auth_port'],
    }
    $designateconfig = merge($eqiaddesignateconfig, $commondesignateconfig)
}

class role::designate::server {
    include role::designate::config::eqiad

    if $::realm == 'labs' and $::openstack_site_override != undef {
        $designateconfig = $::openstack_site_override ? {
            'eqiad' => $role::designate::config::eqiad::designateconfig,
        }
    } else {
        $designateconfig = $::site ? {
            'eqiad' => $role::designate::config::eqiad::designateconfig,
        }
    }

    class { 'openstack::designate::service':
        designateconfig      => $designateconfig,
    }
}
