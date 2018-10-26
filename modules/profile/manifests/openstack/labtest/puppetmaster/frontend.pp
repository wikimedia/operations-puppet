class profile::openstack::labtest::puppetmaster::frontend(
    $designate_host = hiera('profile::openstack::labtest::designate_host'),
    $second_region_designate_host = hiera('profile::openstack::labtest::second_region_designate_host'),
    $puppetmasters = hiera('profile::openstack::labtest::puppetmaster::servers'),
    $puppetmaster_ca = hiera('profile::openstack::labtest::puppetmaster::ca'),
    $puppetmaster_hostname = hiera('profile::openstack::labtest::puppetmaster_hostname'),
    $puppetmaster_webhostname = hiera('profile::openstack::labtest::puppetmaster::web_hostname'),
    $encapi_db_host = hiera('profile::openstack::labtest::puppetmaster::encapi::db_host'),
    $encapi_db_name = hiera('profile::openstack::labtest::puppetmaster::encapi::db_name'),
    $encapi_db_user = hiera('profile::openstack::labtest::puppetmaster::encapi::db_user'),
    $encapi_db_pass = hiera('profile::openstack::labtest::puppetmaster::encapi::db_pass'),
    $encapi_statsd_prefix = hiera('profile::openstack::labtest::puppetmaster::encapi::statsd_prefix'),
    $statsd_host = hiera('profile::openstack::labtest::statsd_host'),
    $labweb_hosts = hiera('profile::openstack::labtest::labweb_hosts'),
    $cert_secret_path = hiera('profile::openstack::labtest::puppetmaster::cert_secret_path'),
    $nova_controller = hiera('profile::openstack::labtest::nova_controller'),
    ) {

    require ::profile::openstack::labtest::clientpackages
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
