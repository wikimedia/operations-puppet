class role::glance::config {
    include passwords::openstack::glance

    $commonglanceconfig = {
        db_name => 'glance',
        db_user => 'glance',
        db_pass => $passwords::openstack::glance::glance_db_pass,
    }
}

class role::glance::config::pmtpa inherits role::glance::config {
    include role::keystone::config::pmtpa

    $keystoneconfig = $role::keystone::config::pmtpa::keystoneconfig

    $db_host = $::realm ? {
        'production' => 'virt0.wikimedia.org',
        'labs'       => $::ipaddress_eth0,
    }

    $bind_ip = $::realm ? {
        'production' => '208.80.152.32',
        'labs'       => $::ipaddress_eth0,
        }

    $pmtpaglanceconfig = {
        db_host                => $db_host,
        bind_ip                => $bind_ip,
        keystone_admin_token   => $keystoneconfig['admin_token'],
        keystone_auth_host     => $keystoneconfig['bind_ip'],
        keystone_auth_protocol => $keystoneconfig['auth_protocol'],
        keystone_auth_port     => $keystoneconfig['auth_port'],
    }
    $glanceconfig = merge($pmtpaglanceconfig, $commonglanceconfig)
}

class role::glance::config::eqiad inherits role::glance::config {
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

    $eqiadglanceconfig = {
        db_host                => $db_host,
        bind_ip                => $bind_ip,
        auth_uri               => $auth_uri,
        keystone_admin_token   => $keystoneconfig['admin_token'],
        keystone_auth_host     => $keystoneconfig['bind_ip'],
        keystone_auth_protocol => $keystoneconfig['auth_protocol'],
        keystone_auth_port     => $keystoneconfig['auth_port'],
    }
    $glanceconfig = merge($eqiadglanceconfig, $commonglanceconfig)
}

class role::glance::server {
    include role::glance::config::pmtpa
    include role::glance::config::eqiad

    if $::realm == 'labs' and $::openstack_site_override != undef {
        $glanceconfig = $::openstack_site_override ? {
            'pmtpa' => $role::glance::config::pmtpa::glanceconfig,
            'eqiad' => $role::glance::config::eqiad::glanceconfig,
        }
    } else {
        $glanceconfig = $::site ? {
            'pmtpa' => $role::glance::config::pmtpa::glanceconfig,
            'eqiad' => $role::glance::config::eqiad::glanceconfig,
        }
    }

    class { 'openstack::glance-service':
        openstack_version => $openstack_version,
        glanceconfig      => $glanceconfig,
    }
}
