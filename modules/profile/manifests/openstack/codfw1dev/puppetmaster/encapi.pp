class profile::openstack::codfw1dev::puppetmaster::encapi(
    Stdlib::Host $encapi_db_host = lookup('profile::openstack::codfw1dev::puppetmaster::encapi::db_host'),
    String $encapi_db_name = lookup('profile::openstack::codfw1dev::puppetmaster::encapi::db_name'),
    String $encapi_db_user = lookup('profile::openstack::codfw1dev::puppetmaster::encapi::db_user'),
    String $encapi_db_pass = lookup('profile::openstack::codfw1dev::puppetmaster::encapi::db_pass'),
    String $acme_certname = lookup('profile::openstack::codfw1dev::puppetmaster::encapi::acme_certname'),
    Array[Stdlib::Fqdn] $openstack_controllers = lookup('profile::openstack::codfw1dev::openstack_controllers'),
    Array[Stdlib::Fqdn] $designate_hosts = lookup('profile::openstack::codfw1dev::designate_hosts'),
    Array[Stdlib::Fqdn] $labweb_hosts = lookup('profile::openstack::codfw1dev::labweb_hosts'),
) {
    class {'::profile::openstack::base::puppetmaster::encapi':
        encapi_db_host        => $encapi_db_host,
        encapi_db_name        => $encapi_db_name,
        encapi_db_user        => $encapi_db_user,
        encapi_db_pass        => $encapi_db_pass,
        acme_certname         => $acme_certname,
        openstack_controllers => $openstack_controllers,
        designate_hosts       => $designate_hosts,
        labweb_hosts          => $labweb_hosts,
    }
}

