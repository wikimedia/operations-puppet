class profile::openstack::codfw1dev::puppetmaster::frontend(
    Array[Stdlib::Fqdn] $openstack_controllers = lookup('profile::openstack::codfw1dev::openstack_controllers'),
    Array[Stdlib::Fqdn] $designate_hosts = lookup('profile::openstack::codfw1dev::designate_hosts'),
    $puppetmasters = lookup('profile::openstack::codfw1dev::puppetmaster::servers'),
    $puppetmaster_ca = lookup('profile::openstack::codfw1dev::puppetmaster::ca'),
    $puppetmaster_hostname = lookup('profile::openstack::codfw1dev::puppetmaster_hostname'),
    $puppetmaster_webhostname = lookup('profile::openstack::codfw1dev::puppetmaster::web_hostname'),
    $encapi_db_host = lookup('profile::openstack::codfw1dev::puppetmaster::encapi::db_host'),
    $encapi_db_name = lookup('profile::openstack::codfw1dev::puppetmaster::encapi::db_name'),
    $encapi_db_user = lookup('profile::openstack::codfw1dev::puppetmaster::encapi::db_user'),
    $encapi_db_pass = lookup('profile::openstack::codfw1dev::puppetmaster::encapi::db_pass'),
    $encapi_statsd_prefix = lookup('profile::openstack::codfw1dev::puppetmaster::encapi::statsd_prefix'),
    $statsd_host = lookup('profile::openstack::codfw1dev::statsd_host'),
    $labweb_hosts = lookup('profile::openstack::codfw1dev::labweb_hosts'),
    $cert_secret_path = lookup('profile::openstack::codfw1dev::puppetmaster::cert_secret_path'),
    ) {

    # until we dismantle labtestpuppetmaster we need some realm checking here to set this up on a VM
    if ( $::realm != 'labs' ) {
        require ::profile::openstack::codfw1dev::clientpackages
    }

    class {'::profile::openstack::base::puppetmaster::frontend':
        openstack_controllers    => $openstack_controllers,
        designate_hosts          => $designate_hosts,
        puppetmasters            => $puppetmasters,
        puppetmaster_ca          => $puppetmaster_ca,
        puppetmaster_hostname    => $puppetmaster_hostname,
        puppetmaster_webhostname => $puppetmaster_webhostname,
        encapi_db_host           => $encapi_db_host,
        encapi_db_name           => $encapi_db_name,
        encapi_db_user           => $encapi_db_user,
        encapi_db_pass           => $encapi_db_pass,
        encapi_statsd_prefix     => $encapi_statsd_prefix,
        statsd_host              => $statsd_host,
        labweb_hosts             => $labweb_hosts,
        cert_secret_path         => $cert_secret_path,
    }
}
