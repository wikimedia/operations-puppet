class profile::openstack::base::puppetmaster::encapi (
    Stdlib::Host $encapi_db_host = lookup('profile::openstack::base::puppetmaster::encapi::encapi_db_host'),
    String $encapi_db_name = lookup('profile::openstack::base::puppetmaster::encapi::encapi_db_name'),
    String $encapi_db_user = lookup('profile::openstack::base::puppetmaster::encapi::encapi_db_user'),
    String $encapi_db_pass = lookup('profile::openstack::base::puppetmaster::encapi::encapi_db_pass'),
    String $acme_certname = lookup('profile::openstack::base::puppetmaster::encapi::acme_certname'),
    Enum['http', 'https'] $keystone_api_protocol = lookup('profile::openstack::base::keystone::auth_protocol'),
    Stdlib::Port $keystone_api_port = lookup('profile::openstack::base::keystone::public_port'),
    Stdlib::Fqdn $keystone_api_fqdn = lookup('profile::openstack::base::keystone_api_fqdn'),
    String[1] $token_validator_username = lookup('profile::openstack::base::puppetmaster::encapi::token_validator_username'),
    String[1] $token_validator_project = lookup('profile::openstack::base::puppetmaster::encapi::token_validator_project'),
    String[1] $token_validator_password = lookup('profile::openstack::base::puppetmaster::encapi::token_validator_password'),
    Array[Stdlib::Fqdn] $openstack_controllers = lookup('profile::openstack::base::puppetmaster::encapi::openstack_controllers'),
    Array[Stdlib::Fqdn] $designate_hosts = lookup('profile::openstack::base::puppetmaster::encapi::designate_hosts'),
    Array[Stdlib::Fqdn] $labweb_hosts = lookup('profile::openstack::base::labweb_hosts'),
) {
    include ::network::constants

    # needed by ssl_ciphersuite('nginx', 'strong') inside the encapi class
    class { '::sslcert::dhparam': }

    class { '::openstack::puppet::master::encapi':
        mysql_host               => $encapi_db_host,
        mysql_db                 => $encapi_db_name,
        mysql_username           => $encapi_db_user,
        mysql_password           => $encapi_db_pass,
        acme_certname            => $acme_certname,
        keystone_api_url         => "${keystone_api_protocol}://${keystone_api_fqdn}:${keystone_api_port}",
        token_validator_username => $token_validator_username,
        token_validator_password => $token_validator_password,
        token_validator_project  => $token_validator_project,
        labweb_hosts             => $labweb_hosts,
        openstack_controllers    => $openstack_controllers,
        designate_hosts          => $designate_hosts,
        labs_instance_ranges     => $::network::constants::labs_networks,
    }

    ferm::service { 'enc-writes':
        proto  => 'tcp',
        port   => '(443 8101)',
        srange => "@resolve((${designate_hosts.join(' ')} ${openstack_controllers.join(' ')} ${labweb_hosts.join(' ')}))",
    }

    ferm::service { 'enc-reads':
        proto  => 'tcp',
        port   => '(8100 8143)',
        srange => '$LABS_NETWORKS',
    }
}
