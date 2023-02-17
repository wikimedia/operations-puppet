# SPDX-License-Identifier: Apache-2.0
class profile::openstack::base::puppetmaster::encapi (
    Stdlib::Host $encapi_db_host = lookup('profile::openstack::base::puppetmaster::encapi::encapi_db_host'),
    String $encapi_db_name = lookup('profile::openstack::base::puppetmaster::encapi::encapi_db_name'),
    String $encapi_db_user = lookup('profile::openstack::base::puppetmaster::encapi::encapi_db_user'),
    String $encapi_db_pass = lookup('profile::openstack::base::puppetmaster::encapi::encapi_db_pass'),
    String[1] $git_repository_url = lookup('profile::openstack::base::puppetmaster::encapi::git_repository_url'),
    String[1] $git_repository_ssh_key = lookup('profile::openstack::base::puppetmaster::encapi::git_repository_ssh_key'),
    Stdlib::Fqdn $git_updater_active_host = lookup('profile::openstack::base::puppetmaster::encapi::git_updater_active_host'),
    String $acme_certname = lookup('profile::openstack::base::puppetmaster::encapi::acme_certname'),
    Enum['http', 'https'] $keystone_api_protocol = lookup('profile::openstack::base::keystone::auth_protocol'),
    Stdlib::Port $keystone_api_port = lookup('profile::openstack::base::keystone::public_port'),
    Stdlib::Fqdn $keystone_api_fqdn = lookup('profile::openstack::base::keystone_api_fqdn'),
    String[1] $token_validator_username = lookup('profile::openstack::base::puppetmaster::encapi::token_validator_username'),
    String[1] $token_validator_project = lookup('profile::openstack::base::puppetmaster::encapi::token_validator_project'),
    String[1] $token_validator_password = lookup('profile::openstack::base::puppetmaster::encapi::token_validator_password'),
) {
    include ::network::constants

    # needed by ssl_ciphersuite('nginx', 'strong') inside the encapi class
    class { '::sslcert::dhparam': }

    class { '::openstack::puppet::master::encapi':
        mysql_host               => $encapi_db_host,
        mysql_db                 => $encapi_db_name,
        mysql_username           => $encapi_db_user,
        mysql_password           => $encapi_db_pass,
        git_repository_url       => $git_repository_url,
        git_repository_path      => '/run/puppet-enc/git-repo',
        git_repository_ssh_key   => $git_repository_ssh_key,
        git_worker_active        => $::facts['fqdn'] == $git_updater_active_host,
        acme_certname            => $acme_certname,
        keystone_api_url         => "${keystone_api_protocol}://${keystone_api_fqdn}:${keystone_api_port}",
        token_validator_username => $token_validator_username,
        token_validator_password => $token_validator_password,
        token_validator_project  => $token_validator_project,
    }

    ferm::service { 'enc':
        proto => 'tcp',
        port  => '443',
    }
}
