class profile::openstack::base::horizon::dashboard_source_deploy(
    $horizon_version = lookup('profile::openstack::base::horizon_version'),
    $openstack_version = lookup('profile::openstack::base::version'),
    $keystone_host = lookup('profile::openstack::base::keystone_host'),
    $wmflabsdotorg_admin = lookup('profile::openstack::base::designate::wmflabsdotorg_admin'),
    $wmflabsdotorg_pass = lookup('profile::openstack::base::designate::wmflabsdotorg_pass'),
    $dhcp_domain = lookup('profile::openstack::base::nova::dhcp_domain'),
    $instance_network_id = lookup('profile::openstack::base::horizon::instance_network_id'),
    $ldap_user_pass = lookup('profile::openstack::base::ldap_user_pass'),
    $webserver_hostname = lookup('profile::openstack::base::horizon::webserver_hostname'),
    $all_regions = lookup('profile::openstack::base::all_regions'),
    $puppet_git_repo_name = lookup('profile::openstack::base::horizon::puppet_git_repo_name'),
    $puppet_git_repo_user = lookup('profile::openstack::base::horizon::puppet_git_repo_user'),
    $maintenance_mode = lookup('profile::openstack::base::horizon::maintenance_mode'),
    $secret_key = lookup('profile::openstack::base::horizon::secret_key'),
    ) {

    class { '::openstack::horizon::source_deploy':
        horizon_version      => $horizon_version,
        openstack_version    => $openstack_version,
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
