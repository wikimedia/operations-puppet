# SPDX-License-Identifier: Apache-2.0
class openstack::magnum::service(
    String $version,
    String $region,
    Array[Stdlib::Fqdn] $openstack_controllers,
    String $db_user,
    String $db_pass,
    String $db_name,
    Stdlib::Fqdn $db_host,
    String $ldap_user_pass,
    String $keystone_admin_uri,
    String $keystone_internal_uri,
    Stdlib::Port $api_bind_port,
    String $rabbit_user,
    String $rabbit_pass,
) {
    class { "openstack::magnum::service::${version}":
        db_user               => $db_user,
        db_pass               => $db_pass,
        db_name               => $db_name,
        db_host               => $db_host,
        ldap_user_pass        => $ldap_user_pass,
        keystone_admin_uri    => $keystone_admin_uri,
        keystone_internal_uri => $keystone_internal_uri,
        api_bind_port         => $api_bind_port,
        rabbit_user           => $rabbit_user,
        rabbit_pass           => $rabbit_pass,
        openstack_controllers => $openstack_controllers,
        region                => $region,
    }

    service { 'magnum-api':
        ensure  => running,
        require => Package['magnum-api'],
    }
    service { 'magnum-conductor':
        ensure  => running,
        require => Package['magnum-conductor'],
    }
}
