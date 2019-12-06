class profile::openstack::base::horizon::dashboard_source_deploy(
    $version = hiera('profile::openstack::base::version'),
    $keystone_host = hiera('profile::openstack::base::keystone_host'),
    $wmflabsdotorg_admin = hiera('profile::openstack::base::designate::wmflabsdotorg_admin'),
    $wmflabsdotorg_pass = hiera('profile::openstack::base::designate::wmflabsdotorg_pass'),
    $dhcp_domain = hiera('profile::openstack::base::nova::dhcp_domain'),
    $instance_network_id = hiera('profile::openstack::base::horizon::instance_network_id'),
    $ldap_user_pass = hiera('profile::openstack::base::ldap_user_pass'),
    $webserver_hostname = hiera('profile::openstack::base::horizon::webserver_hostname'),
    $all_regions = hiera('profile::openstack::base::all_regions'),
    $puppet_git_repo_name = hiera('profile::openstack::base::horizon::puppet_git_repo_name'),
    $puppet_git_repo_user = hiera('profile::openstack::base::horizon::puppet_git_repo_user'),
    $maintenance_mode = hiera('profile::openstack::base::horizon::maintenance_mode'),
    $secret_key = hiera('profile::openstack::base::horizon::secret_key'),
    ) {

    class { '::openstack::horizon::source_deploy':
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
        secret_key           => $secret_key,
    }
    contain '::openstack::horizon::source_deploy'

    ferm::service { 'horizon_http':
        proto  => 'tcp',
        port   => '80',
        srange => '$DOMAIN_NETWORKS'
    }
}
