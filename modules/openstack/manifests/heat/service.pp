# SPDX-License-Identifier: Apache-2.0
class openstack::heat::service(
    String $version,
    Array[Stdlib::Fqdn] $openstack_controllers,
    String $db_user,
    String $db_pass,
    String $db_name,
    Stdlib::Fqdn $db_host,
    String $ldap_user_pass,
    String $keystone_admin_uri,
    String $keystone_internal_uri,
    Stdlib::Port $api_bind_port,
    Stdlib::Port $cfn_api_bind_port,
    String $rabbit_user,
    String $rabbit_pass,
    String[32] $auth_encryption_key,
) {
    class { "openstack::heat::service::${version}":
        db_user               => $db_user,
        db_pass               => $db_pass,
        db_name               => $db_name,
        db_host               => $db_host,
        ldap_user_pass        => $ldap_user_pass,
        keystone_admin_uri    => $keystone_admin_uri,
        keystone_internal_uri => $keystone_internal_uri,
        api_bind_port         => $api_bind_port,
        cfn_api_bind_port     => $cfn_api_bind_port,
        rabbit_user           => $rabbit_user,
        rabbit_pass           => $rabbit_pass,
        openstack_controllers => $openstack_controllers,
        auth_encryption_key   => $auth_encryption_key,
    }

    service { 'heat-api':
        ensure  => running,
        require => Package['heat-api'],
    }
    service { 'heat-engine':
        ensure  => running,
        require => Package['heat-engine'],
    }
    service { 'heat-api-cfn':
        ensure  => running,
        require => Package['heat-api-cfn'],
    }
}
