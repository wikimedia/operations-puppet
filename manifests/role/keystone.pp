class role::keystone::config {
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

class role::keystone::config::eqiad inherits role::keystone::config {
    $eqiadkeystoneconfig = {
        db_host      => $::realm ? {
            'production' => 'virt1000.wikimedia.org',
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
            'production' => '208.80.154.18',
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

class role::keystone::server ($glanceconfig) {
    include role::keystone::config::eqiad

    if $::realm == 'labs' and $::openstack_site_override != undef {
        $keystoneconfig = $::openstack_site_override ? {
            'eqiad' => $role::keystone::config::eqiad::keystoneconfig,
        }
    } else {
        $keystoneconfig = $::site ? {
            'eqiad' => $role::keystone::config::eqiad::keystoneconfig,
        }
    }

    class { 'openstack::keystone::service': keystoneconfig => $keystoneconfig, glanceconfig => $glanceconfig }

    include role::keystone::redis
}

class role::keystone::redis {
    include passwords::openstack::keystone

    if ($::realm == 'production') {
        $replication = {
            'labcontrol2001' => 'virt1000.wikimedia.org'
        }
    } else {
        $replication = {
            'nova-precise3' => 'nova-precise2'
        }
    }

    class { '::redis':
        maxmemory                 => '250mb',
        persist                   => 'aof',
        redis_replication         => $replication,
        password                  => $passwords::openstack::keystone::keystone_db_pass,
        dir                       => '/var/lib/redis/',
        auto_aof_rewrite_min_size => '64mb',
    }
}


class role::keystone::redis::labs {
    include passwords::openstack::keystone

    class { '::redis':
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
