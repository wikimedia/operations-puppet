class profile::openstack::main::puppetmaster::backend(
    $designate_host = hiera('profile::openstack::main::designate_host'),
    $second_region_designate_host = hiera('profile::openstack::main::second_region_designate_host'),
    $puppetmaster_hostname = hiera('profile::openstack::main::puppetmaster_hostname'),
    $puppetmaster_ca = hiera('profile::openstack::main::puppetmaster::ca'),
    $puppetmaster_webhostname = hiera('profile::openstack::main::puppetmaster::web_hostname'),
    $puppetmasters = hiera('profile::openstack::main::puppetmaster::servers'),
    $encapi_db_host = hiera('profile::openstack::main::puppetmaster::encapi::db_host'),
    $encapi_db_name = hiera('profile::openstack::main::puppetmaster::encapi::db_name'),
    $encapi_db_user = hiera('profile::openstack::main::puppetmaster::encapi::db_user'),
    $encapi_db_pass = hiera('profile::openstack::main::puppetmaster::encapi::db_pass'),
    $encapi_statsd_prefix = hiera('profile::openstack::main::puppetmaster::encapi::statsd_prefix'),
    $statsd_host = hiera('profile::openstack::main::statsd_host'),
    $labweb_hosts = hiera('profile::openstack::main::labweb_hosts'),
    $nova_controller = hiera('profile::openstack::main::nova_controller'),
    ) {

    require ::profile::openstack::main::clientpackages
    include ::profile::openstack::main::cumin::master
    class {'::profile::openstack::base::puppetmaster::backend':
        designate_host               => $designate_host,
        second_region_designate_host => $second_region_designate_host,
        puppetmaster_webhostname     => $puppetmaster_webhostname,
        puppetmaster_ca              => $puppetmaster_ca,
        puppetmaster_hostname        => $puppetmaster_hostname,
        puppetmasters                => $puppetmasters,
        encapi_db_host               => $encapi_db_host,
        encapi_db_name               => $encapi_db_name,
        encapi_db_user               => $encapi_db_user,
        encapi_db_pass               => $encapi_db_pass,
        encapi_statsd_prefix         => $encapi_statsd_prefix,
        statsd_host                  => $statsd_host,
        labweb_hosts                 => $labweb_hosts,
        nova_controller              => $nova_controller,
    }
}
