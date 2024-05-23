# SPDX-License-Identifier: Apache-2.0
class profile::openstack::codfw1dev::horizon::docker_deploy(
    String          $horizon_version = lookup('profile::openstack::codfw1dev::horizon_version'),
    String          $openstack_version = lookup('profile::openstack::codfw1dev::version'),
    Stdlib::Fqdn    $keystone_api_fqdn = lookup('profile::openstack::codfw1dev::keystone_api_fqdn'),
    String          $dhcp_domain = lookup('profile::openstack::codfw1dev::nova::dhcp_domain'),
    String          $instance_network_id = lookup('profile::openstack::codfw1dev::horizon::instance_network_id'),
    String          $ldap_user_pass = lookup('profile::openstack::codfw1dev::ldap_user_pass'),
    Stdlib::Fqdn    $webserver_hostname = lookup('profile::openstack::codfw1dev::horizon::webserver_hostname'),
    Array[String]   $all_regions = lookup('profile::openstack::codfw1dev::all_regions'),
    String          $puppet_git_repo_name = lookup('profile::openstack::codfw1dev::horizon::puppet_git_repo_name'),
    Stdlib::Port::User $port = lookup('profile::openstack::codfw1dev::horizon::docker_port', { 'default_value' => 8084 }),
    String          $secret_key = lookup('profile::openstack::codfw1dev::horizon::secret_key'),
    String          $docker_version = lookup('profile::openstack::codfw1dev::horizon::docker_version'),
) {

    class {'::profile::openstack::base::horizon::docker_deploy':
        horizon_version      => $horizon_version,
        openstack_version    => $openstack_version,
        keystone_api_fqdn    => $keystone_api_fqdn,
        dhcp_domain          => $dhcp_domain,
        instance_network_id  => $instance_network_id,
        ldap_user_pass       => $ldap_user_pass,
        webserver_hostname   => $webserver_hostname,
        all_regions          => $all_regions,
        puppet_git_repo_name => $puppet_git_repo_name,
        secret_key           => $secret_key,
        port                 => $port,
        docker_version       => $docker_version,
    }
}
