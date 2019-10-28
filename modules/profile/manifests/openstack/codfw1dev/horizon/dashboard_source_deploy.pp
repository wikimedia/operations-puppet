class profile::openstack::codfw1dev::horizon::dashboard_source_deploy(
    $version = hiera('profile::openstack::codfw1dev::version'),
    $keystone_host = hiera('profile::openstack::codfw1dev::keystone_host'),
    $wmflabsdotorg_admin = hiera('profile::openstack::codfw1dev::designate::wmflabsdotorg_admin'),
    $wmflabsdotorg_pass = hiera('profile::openstack::codfw1dev::designate::wmflabsdotorg_pass'),
    $dhcp_domain = hiera('profile::openstack::codfw1dev::nova::dhcp_domain'),
    $instance_network_id = hiera('profile::openstack::codfw1dev::horizon::instance_network_id'),
    $ldap_user_pass = hiera('profile::openstack::codfw1dev::ldap_user_pass'),
    $webserver_hostname = hiera('profile::openstack::codfw1dev::horizon::webserver_hostname'),
    $all_regions = hiera('profile::openstack::codfw1dev::all_regions'),
    $puppet_git_repo_name = hiera('profile::openstack::codfw1dev::horizon::puppet_git_repo_name'),
    $puppet_git_repo_user = hiera('profile::openstack::codfw1dev::horizon::puppet_git_repo_user'),
    $maintenance_mode = hiera('profile::openstack::codfw1dev::horizon::maintenance_mode'),
    ) {

    require ::profile::openstack::codfw1dev::clientpackages
    class {'::profile::openstack::base::horizon::dashboard_source_deploy':
        version              => $version,
        keystone_host        => $keystone_host,
        wmflabsdotorg_admin  => $wmflabsdotorg_admin,
        wmflabsdotorg_pass   => $wmflabsdotorg_pass,
        dhcp_domain          => $dhcp_domain,
        instance_network_id  => $instance_network_id,
        ldap_user_pass       => $ldap_user_pass,
        webserver_hostname   => $webserver_hostname,
        all_regions          => $all_regions,
        puppet_git_repo_name => $puppet_git_repo_name,
        puppet_git_repo_user => $puppet_git_repo_user,
        maintenance_mode     => $maintenance_mode,
    }
}
