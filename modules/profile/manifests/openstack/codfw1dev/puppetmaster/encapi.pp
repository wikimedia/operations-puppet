class profile::openstack::codfw1dev::puppetmaster::encapi(
    Stdlib::Host $encapi_db_host = lookup('profile::openstack::codfw1dev::puppetmaster::encapi::db_host'),
    String $encapi_db_name = lookup('profile::openstack::codfw1dev::puppetmaster::encapi::db_name'),
    String $encapi_db_user = lookup('profile::openstack::codfw1dev::puppetmaster::encapi::db_user'),
    String $encapi_db_pass = lookup('profile::openstack::codfw1dev::puppetmaster::encapi::db_pass'),
    String $acme_certname = lookup('profile::openstack::codfw1dev::puppetmaster::encapi::acme_certname'),
    Stdlib::Fqdn $keystone_api_fqdn = lookup('profile::openstack::codfw1dev::keystone_api_fqdn'),
    String[1] $token_validator_username = lookup('profile::openstack::codfw1dev::puppetmaster::encapi::token_validator_username'),
    String[1] $token_validator_project = lookup('profile::openstack::codfw1dev::puppetmaster::encapi::token_validator_project'),
    String[1] $token_validator_password = lookup('profile::openstack::codfw1dev::puppetmaster::encapi::token_validator_password'),
    Array[Stdlib::Fqdn] $openstack_controllers = lookup('profile::openstack::codfw1dev::openstack_controllers'),
    Array[Stdlib::Fqdn] $designate_hosts = lookup('profile::openstack::codfw1dev::designate_hosts'),
    Array[Stdlib::Fqdn] $labweb_hosts = lookup('profile::openstack::codfw1dev::labweb_hosts'),
) {
    class {'::profile::openstack::base::puppetmaster::encapi':
        encapi_db_host           => $encapi_db_host,
        encapi_db_name           => $encapi_db_name,
        encapi_db_user           => $encapi_db_user,
        encapi_db_pass           => $encapi_db_pass,
        acme_certname            => $acme_certname,
        keystone_api_fqdn        => $keystone_api_fqdn,
        token_validator_username => $token_validator_username,
        token_validator_password => $token_validator_password,
        token_validator_project  => $token_validator_project,
        openstack_controllers    => $openstack_controllers,
        designate_hosts          => $designate_hosts,
        labweb_hosts             => $labweb_hosts,
    }
}

