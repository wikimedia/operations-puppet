class profile::openstack::base::horizon::dashboard_source_deploy(
    String          $horizon_version = lookup('profile::openstack::base::horizon_version'),
    String          $openstack_version = lookup('profile::openstack::base::version'),
    Stdlib::Fqdn    $keystone_api_fqdn = lookup('profile::openstack::base::keystone_api_fqdn'),
    String          $wmflabsdotorg_admin = lookup('profile::openstack::base::designate::wmflabsdotorg_admin'),
    String          $wmflabsdotorg_pass = lookup('profile::openstack::base::designate::wmflabsdotorg_pass'),
    String          $dhcp_domain = lookup('profile::openstack::base::nova::dhcp_domain'),
    String          $instance_network_id = lookup('profile::openstack::base::horizon::instance_network_id'),
    Hash            $ldap_config = lookup('ldap'),
    String          $ldap_user_pass = lookup('profile::openstack::base::ldap_user_pass'),
    Stdlib::Fqdn    $webserver_hostname = lookup('profile::openstack::base::horizon::webserver_hostname'),
    Array[String]   $all_regions = lookup('profile::openstack::base::all_regions'),
    String          $puppet_git_repo_name = lookup('profile::openstack::base::horizon::puppet_git_repo_name'),
    String          $puppet_git_repo_user = lookup('profile::openstack::base::horizon::puppet_git_repo_user'),
    Boolean         $maintenance_mode = lookup('profile::openstack::base::horizon::maintenance_mode'),
    String          $secret_key = lookup('profile::openstack::base::horizon::secret_key'),
    Hash            $proxy_zone_dict = lookup('profile::openstack::base::horizon::proxy_zone_dict'),
    Hash            $proxy_zone_passwords = lookup('profile::openstack::base::horizon::proxy_zone_passwords'),
) {

    $ldap_rw_host = $ldap_config['rw-server']

    class { '::openstack::horizon::source_deploy':
        horizon_version      => $horizon_version,
        openstack_version    => $openstack_version,
        keystone_api_fqdn    => $keystone_api_fqdn,
        wmflabsdotorg_admin  => $wmflabsdotorg_admin,
        wmflabsdotorg_pass   => $wmflabsdotorg_pass,
        dhcp_domain          => $dhcp_domain,
        instance_network_id  => $instance_network_id,
        ldap_rw_host         => $ldap_rw_host,
        ldap_user_pass       => $ldap_user_pass,
        webserver_hostname   => $webserver_hostname,
        all_regions          => $all_regions,
        puppet_git_repo_name => $puppet_git_repo_name,
        puppet_git_repo_user => $puppet_git_repo_user,
        maintenance_mode     => $maintenance_mode,
        secret_key           => $secret_key,
        proxy_zone_dict      => $proxy_zone_dict,
        proxy_zone_passwords => $proxy_zone_passwords,
    }

    contain '::openstack::horizon::source_deploy'

    # Horizon error logs to ELK.  The Apache log is called horizon_error
    #  but it contains anything that the Horizon python code logs.
    #
    # The arcane startmsg_regex is meant to detect continued lines
    #  in python stack-traces. It declares a new message to begine
    #  with a timestamp followed by a single space; two spaces
    #  is taken to be the indented continuation of a message.
    rsyslog::input::file { 'horizon_error':
        path           => '/var/log/apache2/horizon_error.log',
        syslog_tag     => 'horizon',
        startmsg_regex => '^[[:digit:]-]{10} [[:digit:]:]{8}.[[:digit:]]* [^ ]',
    }
}
