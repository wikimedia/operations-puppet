class profile::openstack::main::puppetmaster::backend(
    $labs_instance_range = hiera('profile::openstack::main::nova::fixed_range'),
    $horizon_host = hiera('profile::openstack::main::horizon_host'),
    $designate_host = hiera('profile::openstack::main::designate_host'),
    $puppetmaster_hostname = hiera('profile::openstack::main::puppetmaster_hostname'),
    $puppetmaster_ca = hiera('profile::openstack::main::puppetmaster::ca'),
    $puppetmasters = hiera('profile::openstack::main::puppetmaster::servers'),
    $baremetal_servers = hiera('profile::openstack::main::puppetmaster::baremetal'),
    $encapi_db_host = hiera('profile::openstack::main::puppetmaster::encapi::db_host'),
    $encapi_db_name = hiera('profile::openstack::main::puppetmaster::encapi::db_name'),
    $encapi_db_user = hiera('profile::openstack::main::puppetmaster::encapi::db_user'),
    $encapi_db_pass = hiera('profile::openstack::main::puppetmaster::encapi::db_pass'),
    $encapi_statsd_prefix = hiera('profile::openstack::main::puppetmaster::encapi::statsd_prefix'),
    $statsd_host = hiera('profile::openstack::main::statsd_host'),
    ) {

    require ::profile::openstack::main::clientlib
    include ::profile::openstack::main::cumin::master
    class {'::profile::openstack::base::puppetmaster::backend':
        labs_instance_range   => $labs_instance_range,
        horizon_host          => $horizon_host,
        designate_host        => $designate_host,
        puppetmaster_ca       => $puppetmaster_ca,
        puppetmaster_hostname => $puppetmaster_hostname,
        puppetmasters         => $puppetmasters,
        baremetal_servers     => $baremetal_servers,
        encapi_db_host        => $encapi_db_host,
        encapi_db_name        => $encapi_db_name,
        encapi_db_user        => $encapi_db_user,
        encapi_db_pass        => $encapi_db_pass,
        encapi_statsd_prefix  => $encapi_statsd_prefix,
        statsd_host           => $statsd_host,
    }
}
