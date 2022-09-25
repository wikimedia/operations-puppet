class profile::openstack::codfw1dev::horizon::dashboard_source_deploy(
    String          $horizon_version = lookup('profile::openstack::codfw1dev::horizon_version'),
    String          $openstack_version = lookup('profile::openstack::codfw1dev::version'),
    Stdlib::Fqdn    $keystone_api_fqdn = lookup('profile::openstack::codfw1dev::keystone_api_fqdn'),
    String          $dhcp_domain = lookup('profile::openstack::codfw1dev::nova::dhcp_domain'),
    String          $instance_network_id = lookup('profile::openstack::codfw1dev::horizon::instance_network_id'),
    String          $ldap_user_pass = lookup('profile::openstack::codfw1dev::ldap_user_pass'),
    Stdlib::Fqdn    $webserver_hostname = lookup('profile::openstack::codfw1dev::horizon::webserver_hostname'),
    Array[String]   $all_regions = lookup('profile::openstack::codfw1dev::all_regions'),
    String          $puppet_git_repo_name = lookup('profile::openstack::codfw1dev::horizon::puppet_git_repo_name'),
    String          $puppet_git_repo_user = lookup('profile::openstack::codfw1dev::horizon::puppet_git_repo_user'),
    Boolean         $maintenance_mode = lookup('profile::openstack::codfw1dev::horizon::maintenance_mode'),
    String          $secret_key = lookup('profile::openstack::codfw1dev::horizon::secret_key'),
) {

    require ::profile::openstack::codfw1dev::clientpackages
    class {'::profile::openstack::base::horizon::dashboard_source_deploy':
        horizon_version      => $horizon_version,
        openstack_version    => $openstack_version,
        keystone_api_fqdn    => $keystone_api_fqdn,
        dhcp_domain          => $dhcp_domain,
        instance_network_id  => $instance_network_id,
        ldap_user_pass       => $ldap_user_pass,
        webserver_hostname   => $webserver_hostname,
        all_regions          => $all_regions,
        puppet_git_repo_name => $puppet_git_repo_name,
        puppet_git_repo_user => $puppet_git_repo_user,
        maintenance_mode     => $maintenance_mode,
        secret_key           => $secret_key,
    }
}
