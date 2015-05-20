class role::glance::config {
    include passwords::openstack::glance
    include passwords::labs::rabbitmq

    $commonglanceconfig = {
        db_name     => 'glance',
        db_user     => 'glance',
        db_pass     => $passwords::openstack::glance::glance_db_pass,
        rabbit_user => $passwords::labs::rabbitmq::rabbit_userid,
        rabbit_pass => $passwords::labs::rabbitmq::rabbit_password,
    }
}

class role::glance::config::eqiad inherits role::glance::config {
    include role::keystone::config::eqiad

    $glance_controller = hiera('labs_glance_controller')

    $keystoneconfig = $role::keystone::config::eqiad::keystoneconfig

    $db_host = $::realm ? {
        'production' => 'm5-master.eqiad.wmnet',
        'labs'       => $::ipaddress_eth0,
    }

    $bind_ip = $::realm ? {
        'production' => ipresolve($glance_controller, 4),
        'labs'       => $::ipaddress_eth0,
    }

    $auth_uri = $::realm ? {
        'production' => "${glance_controller}:5000',
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
    include role::glance::config::eqiad

    if $::realm == 'labs' and $::openstack_site_override != undef {
        $glanceconfig = $::openstack_site_override ? {
            'eqiad' => $role::glance::config::eqiad::glanceconfig,
        }
    } else {
        $glanceconfig = $::site ? {
            'eqiad' => $role::glance::config::eqiad::glanceconfig,
        }
    }

    class { 'openstack::glance::service':
        glanceconfig      => $glanceconfig,
    }
}
