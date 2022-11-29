class profile::openstack::codfw1dev::designate::service(
    $version = lookup('profile::openstack::codfw1dev::version'),
    Array[Stdlib::Fqdn] $designate_hosts = lookup('profile::openstack::codfw1dev::designate_hosts'),
    Array[Stdlib::Fqdn] $openstack_controllers = lookup('profile::openstack::codfw1dev::openstack_controllers'),
    Stdlib::Fqdn $keystone_fqdn = lookup('profile::openstack::codfw1dev::keystone_api_fqdn'),
    $puppetmaster_hostname = lookup('profile::openstack::codfw1dev::puppetmaster_hostname'),
    $db_pass = lookup('profile::openstack::codfw1dev::designate::db_pass'),
    $db_host = lookup('profile::openstack::codfw1dev::designate::db_host'),
    $domain_id_internal_forward = lookup('profile::openstack::codfw1dev::designate::domain_id_internal_forward'),
    $domain_id_internal_forward_legacy = lookup('profile::openstack::codfw1dev::designate::domain_id_internal_forward_legacy'),
    $domain_id_internal_reverse = lookup('profile::openstack::codfw1dev::designate::domain_id_internal_reverse'),
    $ldap_user_pass = lookup('profile::openstack::codfw1dev::ldap_user_pass'),
    $pdns_api_key = lookup('profile::openstack::codfw1dev::pdns::api_key'),
    $db_admin_pass = lookup('profile::openstack::codfw1dev::designate::db_admin_pass'),
    Array[Stdlib::Fqdn] $pdns_hosts = lookup('profile::openstack::codfw1dev::pdns::hosts'),
    Array[Stdlib::Fqdn] $rabbitmq_nodes = lookup('profile::openstack::codfw1dev::rabbitmq_nodes'),
    $rabbit_pass = lookup('profile::openstack::codfw1dev::nova::rabbit_pass'),
    $osm_host = lookup('profile::openstack::codfw1dev::osm_host'),
    $labweb_hosts = lookup('profile::openstack::codfw1dev::labweb_hosts'),
    $region = lookup('profile::openstack::codfw1dev::region'),
    $puppet_git_repo_name = lookup('profile::openstack::codfw1dev::horizon::puppet_git_repo_name'),
    $puppet_git_repo_user = lookup('profile::openstack::codfw1dev::horizon::puppet_git_repo_user'),
    Integer $mcrouter_port = lookup('profile::openstack::codfw1dev::designate::mcrouter_port'),
) {

    class{'::profile::openstack::base::designate::service':
        version                           => $version,
        designate_hosts                   => $designate_hosts,
        keystone_fqdn                     => $keystone_fqdn,
        db_pass                           => $db_pass,
        db_host                           => $db_host,
        domain_id_internal_forward        => $domain_id_internal_forward,
        domain_id_internal_forward_legacy => $domain_id_internal_forward_legacy,
        domain_id_internal_reverse        => $domain_id_internal_reverse,
        puppetmaster_hostname             => $puppetmaster_hostname,
        openstack_controllers             => $openstack_controllers,
        ldap_user_pass                    => $ldap_user_pass,
        pdns_api_key                      => $pdns_api_key,
        db_admin_pass                     => $db_admin_pass,
        pdns_hosts                        => $pdns_hosts,
        rabbitmq_nodes                    => $rabbitmq_nodes,
        rabbit_pass                       => $rabbit_pass,
        osm_host                          => $osm_host,
        labweb_hosts                      => $labweb_hosts,
        region                            => $region,
        puppet_git_repo_name              => $puppet_git_repo_name,
        puppet_git_repo_user              => $puppet_git_repo_user,
        mcrouter_port                     => $mcrouter_port,
    }
    contain '::profile::openstack::base::designate::service'
}
