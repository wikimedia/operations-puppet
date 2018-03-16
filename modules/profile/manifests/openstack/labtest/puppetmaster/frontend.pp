class profile::openstack::labtest::puppetmaster::frontend(
    $labs_instance_range = hiera('profile::openstack::labtest::nova::fixed_range'),
    $designate_host = hiera('profile::openstack::labtest::designate_host'),
    $puppetmasters = hiera('profile::openstack::labtest::puppetmaster::servers'),
    $puppetmaster_ca = hiera('profile::openstack::labtest::puppetmaster::ca'),
    $puppetmaster_hostname = hiera('profile::openstack::labtest::puppetmaster_hostname'),
    $puppetmaster_webhostname = hiera('profile::openstack::labtest::puppetmaster::web_hostname'),
    $baremetal_servers = hiera('profile::openstack::labtest::puppetmaster::baremetal'),
    $encapi_db_host = hiera('profile::openstack::labtest::puppetmaster::encapi::db_host'),
    $encapi_db_name = hiera('profile::openstack::labtest::puppetmaster::encapi::db_name'),
    $encapi_db_user = hiera('profile::openstack::labtest::puppetmaster::encapi::db_user'),
    $encapi_db_pass = hiera('profile::openstack::labtest::puppetmaster::encapi::db_pass'),
    $encapi_statsd_prefix = hiera('profile::openstack::labtest::puppetmaster::encapi::statsd_prefix'),
    $statsd_host = hiera('profile::openstack::labtest::statsd_host'),
    $labweb_hosts = hiera('profile::openstack::labtest::labweb_hosts'),
    ) {

    require ::profile::openstack::labtest::clientlib
    class {'::profile::openstack::base::puppetmaster::frontend':
        labs_instance_range      => $labs_instance_range,
        designate_host           => $designate_host,
        puppetmasters            => $puppetmasters,
        puppetmaster_ca          => $puppetmaster_ca,
        puppetmaster_hostname    => $puppetmaster_hostname,
        puppetmaster_webhostname => $puppetmaster_webhostname,
        baremetal_servers        => $baremetal_servers,
        encapi_db_host           => $encapi_db_host,
        encapi_db_name           => $encapi_db_name,
        encapi_db_user           => $encapi_db_user,
        encapi_db_pass           => $encapi_db_pass,
        encapi_statsd_prefix     => $encapi_statsd_prefix,
        statsd_host              => $statsd_host,
        labweb_hosts             => $labweb_hosts,
    }
}
