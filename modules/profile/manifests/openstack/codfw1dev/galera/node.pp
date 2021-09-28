class profile::openstack::codfw1dev::galera::node(
    Integer                $server_id              = lookup('profile::openstack::codfw1dev::galera::server_id'),
    Boolean                $enabled                = lookup('profile::openstack::codfw1dev::galera::enabled'),
    Stdlib::Port           $listen_port            = lookup('profile::openstack::codfw1dev::galera::listen_port'),
    String                 $prometheus_db_pass     = lookup('profile::openstack::codfw1dev::galera::prometheus_db_pass'),
    Array[Stdlib::Fqdn]    $openstack_controllers  = lookup('profile::openstack::codfw1dev::openstack_controllers'),
    Array[Stdlib::Fqdn]    $designate_hosts        = lookup('profile::openstack::codfw1dev::designate_hosts'),
    Array[Stdlib::Fqdn]    $labweb_hosts           = lookup('profile::openstack::codfw1dev::labweb_hosts'),
    Stdlib::Fqdn           $puppetmaster           = lookup('profile::openstack::codfw1dev::puppetmaster::web_hostname'),
    Optional[Stdlib::Fqdn] $manila_sharecontroller = lookup('profile::openstack::codfw1dev::manila_sharecontroller', {default_value => undef}),
    ) {

    class {'::profile::openstack::base::galera::node':
        server_id              => $server_id,
        enabled                => $enabled,
        listen_port            => $listen_port,
        openstack_controllers  => $openstack_controllers,
        designate_hosts        => $designate_hosts,
        labweb_hosts           => $labweb_hosts,
        puppetmaster           => $puppetmaster,
        prometheus_db_pass     => $prometheus_db_pass,
        manila_sharecontroller => $manila_sharecontroller,
    }
}
