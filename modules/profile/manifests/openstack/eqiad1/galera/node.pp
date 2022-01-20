class profile::openstack::eqiad1::galera::node(
    Integer             $server_id             = lookup('profile::openstack::eqiad1::galera::server_id'),
    Boolean             $enabled               = lookup('profile::openstack::eqiad1::galera::enabled'),
    Stdlib::Port        $listen_port           = lookup('profile::openstack::eqiad1::galera::listen_port'),
    String              $prometheus_db_pass    = lookup('profile::openstack::eqiad1::galera::prometheus_db_pass'),
    Array[Stdlib::Fqdn] $openstack_controllers = lookup('profile::openstack::eqiad1::openstack_controllers'),
    Array[Stdlib::Fqdn] $designate_hosts       = lookup('profile::openstack::eqiad1::designate_hosts'),
    Array[Stdlib::Fqdn] $labweb_hosts          = lookup('profile::openstack::eqiad1::labweb_hosts'),
    Stdlib::Fqdn        $puppetmaster          = lookup('profile::openstack::eqiad1::puppetmaster::web_hostname'),
    Array[Stdlib::Fqdn] $cinder_backup_nodes   = lookup('profile::openstack::eqiad1::cinder::backup::nodes'),
    ) {

    class {'::profile::openstack::base::galera::node':
        server_id             => $server_id,
        enabled               => $enabled,
        listen_port           => $listen_port,
        openstack_controllers => $openstack_controllers,
        designate_hosts       => $designate_hosts,
        labweb_hosts          => $labweb_hosts,
        puppetmaster          => $puppetmaster,
        prometheus_db_pass    => $prometheus_db_pass,
        cinder_backup_nodes   => $cinder_backup_nodes,
    }
}
