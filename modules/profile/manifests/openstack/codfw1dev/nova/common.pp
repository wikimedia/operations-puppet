class profile::openstack::codfw1dev::nova::common(
    $version = lookup('profile::openstack::codfw1dev::version'),
    $region = lookup('profile::openstack::codfw1dev::region'),
    $db_pass = lookup('profile::openstack::codfw1dev::nova::db_pass'),
    $db_host = lookup('profile::openstack::codfw1dev::nova::db_host'),
    $db_name = lookup('profile::openstack::codfw1dev::nova::db_name'),
    $db_user = lookup('profile::openstack::codfw1dev::nova::db_user'),
    $db_name_api = lookup('profile::openstack::codfw1dev::nova::db_name_api'),
    $db_name_cell = lookup('profile::openstack::codfw1dev::nova::db_name_cell'),
    Array[Stdlib::Fqdn] $openstack_controllers = lookup('profile::openstack::codfw1dev::openstack_controllers'),
    Array[Stdlib::Fqdn] $rabbitmq_nodes = lookup('profile::openstack::codfw1dev::rabbitmq_nodes'),
    Stdlib::Fqdn $keystone_api_fqdn = lookup('profile::openstack::codfw1dev::keystone_api_fqdn'),
    $ldap_user_pass = lookup('profile::openstack::codfw1dev::ldap_user_pass'),
    $rabbit_pass = lookup('profile::openstack::codfw1dev::nova::rabbit_pass'),
    $metadata_proxy_shared_secret = lookup('profile::openstack::codfw1dev::neutron::metadata_proxy_shared_secret'),
    Stdlib::Port $metadata_listen_port = lookup('profile::openstack::codfw1dev::nova::metadata_listen_port'),
    Stdlib::Port $osapi_compute_listen_port = lookup('profile::openstack::codfw1dev::nova::osapi_compute_listen_port'),
    ) {

    class {'::profile::openstack::base::nova::common':
        version                      => $version,
        region                       => $region,
        db_pass                      => $db_pass,
        db_host                      => $db_host,
        db_name                      => $db_name,
        db_user                      => $db_user,
        db_name_api                  => $db_name_api,
        db_name_cell                 => $db_name_cell,
        openstack_controllers        => $openstack_controllers,
        rabbitmq_nodes               => $rabbitmq_nodes,
        keystone_api_fqdn            => $keystone_api_fqdn,
        ldap_user_pass               => $ldap_user_pass,
        rabbit_pass                  => $rabbit_pass,
        metadata_listen_port         => $metadata_listen_port,
        metadata_proxy_shared_secret => $metadata_proxy_shared_secret,
        osapi_compute_listen_port    => $osapi_compute_listen_port,
    }
    contain '::profile::openstack::base::nova::common'
}
