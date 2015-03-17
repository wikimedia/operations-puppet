class role::designate::config {
    include openstack
    include passwords::designate
    include passwords::pdns

    $commondesignateconfig = {
        db_name =>      'designate',
        db_user =>      $passwords::designate::db_user,
        db_pass =>      $passwords::designate::db_pass,
        pdns_db_name => 'pdns',
        pdns_db_user => $passwords::pdns::db_user,
        pdns_db_pass => $passwords::pdns::db_pass,
        pdns_db_admin_user => $passwords::pdns::db_admin_user,
        pdns_db_admin_pass => $passwords::pdns::db_admin_pass,
    }
}

class role::designate::config::eqiad inherits role::designate::config {
    include role::keystone::config::eqiad

    $controller_hostname = $::realm ? {
        'production' => 'virt1000.wikimedia.org',
        'labs'       => $nova_controller_hostname ? {
            undef   => $::ipaddress_eth0,
            default => $nova_controller_hostname,
        }
    }

    $keystoneconfig = $role::keystone::config::eqiad::keystoneconfig

    $db_host = $::realm ? {
        'production' => 'm1-master.eqiad.wmnet',
        'labs'       => $::ipaddress_eth0,
    }

    $pdns_db_host = $::realm ? {
        'production' => 'm1-master.eqiad.wmnet',
        'labs'       => $::ipaddress_eth0,
    }

    $auth_uri = $::realm ? {
        'production' => 'http://virt1000.wikimedia.org:5000',
        'labs'       => "http://$::ipaddress_eth0:5000",
    }

    $eqiaddesignateconfig = {
        db_host                => $db_host,
        pdns_db_host           => $pdns_db_host,
        auth_uri               => $auth_uri,
        rabbit_host            => $controller_hostname,
        keystone_admin_token   => $keystoneconfig['admin_token'],
        keystone_auth_host     => $keystoneconfig['bind_ip'],
        keystone_auth_protocol => $keystoneconfig['auth_protocol'],
        keystone_auth_port     => $keystoneconfig['auth_port'],
        dhcp_domain            => 'eqiad',
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
