class profile::openstack::eqiad1::puppetmaster::frontend(
    $designate_host = hiera('profile::openstack::eqiad1::designate_host'),
    $second_region_designate_host = hiera('profile::openstack::eqiad1::second_region_designate_host'),
    $puppetmasters = hiera('profile::openstack::eqiad1::puppetmaster::servers'),
    $puppetmaster_ca = hiera('profile::openstack::eqiad1::puppetmaster::ca'),
    $puppetmaster_hostname = hiera('profile::openstack::eqiad1::puppetmaster_hostname'),
    $puppetmaster_webhostname = hiera('profile::openstack::eqiad1::puppetmaster::web_hostname'),
    $encapi_db_host = hiera('profile::openstack::eqiad1::puppetmaster::encapi::db_host'),
    $encapi_db_name = hiera('profile::openstack::eqiad1::puppetmaster::encapi::db_name'),
    $encapi_db_user = hiera('profile::openstack::eqiad1::puppetmaster::encapi::db_user'),
    $encapi_db_pass = hiera('profile::openstack::eqiad1::puppetmaster::encapi::db_pass'),
    $encapi_statsd_prefix = hiera('profile::openstack::eqiad1::puppetmaster::encapi::statsd_prefix'),
    $statsd_host = hiera('profile::openstack::eqiad1::statsd_host'),
    $labweb_hosts = hiera('profile::openstack::eqiad1::labweb_hosts'),
    $cert_secret_path = hiera('profile::openstack::eqiad1::puppetmaster::cert_secret_path'),
    $nova_controller = hiera('profile::openstack::eqiad1::nova_controller'),
    $enable_cumin = hiera('profile::openstack::eqiad1::puppetmaster::enable_cumin'),
    ) {

    if $enable_cumin {
        include ::profile::openstack::eqiad1::cumin::master
    }
    class {'::profile::openstack::base::puppetmaster::frontend':
        designate_host               => $designate_host,
        second_region_designate_host => $second_region_designate_host,
        puppetmasters                => $puppetmasters,
        puppetmaster_ca              => $puppetmaster_ca,
        puppetmaster_hostname        => $puppetmaster_hostname,
        puppetmaster_webhostname     => $puppetmaster_webhostname,
        encapi_db_host               => $encapi_db_host,
        encapi_db_name               => $encapi_db_name,
        encapi_db_user               => $encapi_db_user,
        encapi_db_pass               => $encapi_db_pass,
        encapi_statsd_prefix         => $encapi_statsd_prefix,
        statsd_host                  => $statsd_host,
        labweb_hosts                 => $labweb_hosts,
        cert_secret_path             => $cert_secret_path,
        nova_controller              => $nova_controller,
    }
}
