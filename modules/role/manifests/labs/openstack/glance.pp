class role::labs::openstack::glance::config {

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

class role::labs::openstack::glance::config::eqiad inherits role::labs::openstack::glance::config {

    include role::labs::openstack::keystone::config::eqiad

    $keystoneconfig = $role::labs::openstack::keystone::config::eqiad::keystoneconfig
    $keystone_host  = hiera('labs_keystone_host')
    $db_host        = 'm5-master.eqiad.wmnet'
    $bind_ip        = $::ipaddress_eth0
    $auth_uri       = "http://${keystone_host}:5000"

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

class role::labs::openstack::glance::server {

    include role::labs::openstack::glance::config::eqiad

    $glanceconfig = $::site ? {
        'eqiad' => $role::labs::openstack::glance::config::eqiad::glanceconfig,
    }

    class { 'openstack::glance::service':
        glanceconfig      => $glanceconfig,
    }
}
