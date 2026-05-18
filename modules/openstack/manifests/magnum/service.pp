# SPDX-License-Identifier: Apache-2.0
class openstack::magnum::service(
    String $version,
    String $region,
    Array[Stdlib::Fqdn] $memcached_nodes,
    Array[Stdlib::Fqdn] $rabbitmq_nodes,
    String $db_user,
    String $db_pass,
    String $db_name,
    Stdlib::Fqdn $etcd_discovery_host,
    Stdlib::Fqdn $db_host,
    String $ldap_user_pass,
    Stdlib::Fqdn $keystone_fqdn,
    Stdlib::Port $api_bind_port,
    String $rabbit_user,
    String $rabbit_pass,
    String $domain_admin_pass,
    Boolean $heat_driver,
    Boolean $capi_driver,
    Stdlib::HTTPSUrl $helm_chart_repo,
) {
    class { "openstack::magnum::service::${version}":
        db_user             => $db_user,
        db_pass             => $db_pass,
        db_name             => $db_name,
        db_host             => $db_host,
        etcd_discovery_host => $etcd_discovery_host,
        ldap_user_pass      => $ldap_user_pass,
        keystone_fqdn       => $keystone_fqdn,
        api_bind_port       => $api_bind_port,
        rabbit_user         => $rabbit_user,
        rabbit_pass         => $rabbit_pass,
        memcached_nodes     => $memcached_nodes,
        rabbitmq_nodes      => $rabbitmq_nodes,
        region              => $region,
        domain_admin_pass   => $domain_admin_pass,
        heat_driver         => $heat_driver,
        capi_driver         => $capi_driver,
        helm_chart_repo     => $helm_chart_repo,
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
