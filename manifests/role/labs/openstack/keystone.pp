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
        db_host      => $::realm ? {
            'production' => 'm5-master.eqiad.wmnet',
            'labs'       => $nova_controller_hostname ? {
                undef   => $::ipaddress_eth0,
                default => $nova_controller_hostname,
            }
        },
        ldap_host    => $::realm ? {
            'production' => 'ldap-eqiad.wikimedia.org',
            'labs'       => $nova_controller_hostname ? {
                undef   => $::ipaddress_eth0,
                default => $nova_controller_hostname,
            }
        },
        bind_ip      => $::realm ? {
            'production' => ipresolve($keystone_host,4),
            'labs'       => $nova_controller_ip ? {
                undef   => $::ipaddress_eth0,
                default => $nova_controller_ip,
            }
        },
        token_driver => $::realm ? {
            # Temporarily disable the redis keystone driver... it doesn't work in icehouse
            'production' => 'normal',
            'labs'       => 'redis',
        },
    }
    $keystoneconfig = merge($eqiadkeystoneconfig, $commonkeystoneconfig)
}

class role::labs::openstack::keystone::server ($glanceconfig) {
    include role::labs::openstack::keystone::config::eqiad

    if $::realm == 'labs' and $::openstack_site_override != undef {
        $keystoneconfig = $::openstack_site_override ? {
            'eqiad' => $role::labs::openstack::keystone::config::eqiad::keystoneconfig,
        }
    } else {
        $keystoneconfig = $::site ? {
            'eqiad' => $role::labs::openstack::keystone::config::eqiad::keystoneconfig,
        }
    }

    class { 'openstack::keystone::service': keystoneconfig => $keystoneconfig, glanceconfig => $glanceconfig }

    include role::labs::openstack::keystone::redis
}

class role::labs::openstack::keystone::redis {
    include passwords::openstack::keystone

    $nova_controller = hiera('labs_nova_controller')

    if ($::realm == 'production') {
        $replication = {
            'labcontrol2001' => $nova_controller
        }
    } else {
        $replication = {
            'nova-precise3' => 'nova-precise2'
        }
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


class role::labs::openstack::keystone::redis::labs {
    include passwords::openstack::keystone

    class { '::redis::legacy':
        maxmemory                 => '250mb',
        persist                   => 'aof',
        redis_replication         => {
            'nova-precise3' => 'nova-precise2'
        },
        password                  => $passwords::openstack::keystone::keystone_db_pass,
        dir                       => '/var/lib/redis/',
        auto_aof_rewrite_min_size => '64mb',
    }
}
