class role::labs::openstack::keystone::config {

    include passwords::openstack::keystone

    $commonkeystoneconfig = {
        db_name                    => 'keystone',
        db_user                    => 'keystone',
        db_pass                    => $passwords::openstack::keystone::keystone_db_pass,
        ldap_base_dn               => 'dc=wikimedia,dc=org',
        ldap_user_dn               => 'uid=novaadmin,ou=people,dc=wikimedia,dc=org',
        ldap_user_id_attribute     => 'uid',
        ldap_tenant_id_attribute   => 'cn',
        ldap_user_name_attribute   => 'uid',
        ldap_tenant_name_attribute => 'cn',
        ldap_user_pass             => $passwords::openstack::keystone::keystone_ldap_user_pass,
        ldap_proxyagent            => 'cn=proxyagent,ou=profile,dc=wikimedia,dc=org',
        ldap_proxyagent_pass       => $passwords::openstack::keystone::keystone_ldap_proxyagent_pass,
        auth_protocol              => 'http',
        auth_port                  => '35357',
        admin_token                => $passwords::openstack::keystone::keystone_admin_token,
        token_driver_password      => $passwords::openstack::keystone::keystone_db_pass,
    }
}

class role::labs::openstack::keystone::config::eqiad inherits role::labs::openstack::keystone::config {

    $keystone_host = hiera('labs_keystone_host')

    $eqiadkeystoneconfig = {
        db_host      => m5-master.eqiad.wmnet',
        ldap_host    => 'ldap-eqiad.wikimedia.org',
        bind_ip      => ipresolve($keystone_host,4),
        # Temporarily disable the redis keystone driver... it doesn't work in icehouse
        token_driver => 'normal',
    }
    $keystoneconfig = merge($eqiadkeystoneconfig, $commonkeystoneconfig)
}

class role::labs::openstack::keystone::server ($glanceconfig) {

    include role::labs::openstack::keystone::config::eqiad
    include role::labs::openstack::keystone::redis

    $keystoneconfig = $::site ? {
        'eqiad' => $role::labs::openstack::keystone::config::eqiad::keystoneconfig,
    }

    class { 'openstack::keystone::service':
        keystoneconfig => $keystoneconfig,
        glanceconfig => $glanceconfig,
    }
}

class role::labs::openstack::keystone::redis {

    include passwords::openstack::keystone

    $nova_controller = hiera('labs_nova_controller')

    $replication = {
        'labcontrol2001' => $nova_controller
    }

    class { '::redis::legacy':
        maxmemory                 => '250mb',
        persist                   => 'aof',
        redis_replication         => $replication,
        password                  => $passwords::openstack::keystone::keystone_db_pass,
        dir                       => '/var/lib/redis/',
        auto_aof_rewrite_min_size => '64mb',
    }
}
