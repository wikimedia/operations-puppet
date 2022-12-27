# SPDX-License-Identifier: Apache-2.0
class profile::openstack::codfw1dev::puppetmaster::encapi(
    Stdlib::Host $encapi_db_host = lookup('profile::openstack::codfw1dev::puppetmaster::encapi::db_host'),
    String $encapi_db_name = lookup('profile::openstack::codfw1dev::puppetmaster::encapi::db_name'),
    String $encapi_db_user = lookup('profile::openstack::codfw1dev::puppetmaster::encapi::db_user'),
    String $encapi_db_pass = lookup('profile::openstack::codfw1dev::puppetmaster::encapi::db_pass'),
    String[1] $git_repository_url = lookup('profile::openstack::codfw1dev::puppetmaster::encapi::git_repository_url'),
    String[1] $git_repository_ssh_key = lookup('profile::openstack::codfw1dev::puppetmaster::encapi::git_repository_ssh_key'),
    Stdlib::Fqdn $git_updater_active_host = lookup('profile::openstack::codfw1dev::puppetmaster::encapi::git_updater_active_host'),
    String $acme_certname = lookup('profile::openstack::codfw1dev::puppetmaster::encapi::acme_certname'),
    Stdlib::Fqdn $keystone_api_fqdn = lookup('profile::openstack::codfw1dev::keystone_api_fqdn'),
    String[1] $token_validator_username = lookup('profile::openstack::codfw1dev::puppetmaster::encapi::token_validator_username'),
    String[1] $token_validator_project = lookup('profile::openstack::codfw1dev::puppetmaster::encapi::token_validator_project'),
    String[1] $token_validator_password = lookup('profile::openstack::codfw1dev::puppetmaster::encapi::token_validator_password'),
) {
    class {'::profile::openstack::base::puppetmaster::encapi':
        encapi_db_host           => $encapi_db_host,
        encapi_db_name           => $encapi_db_name,
        encapi_db_user           => $encapi_db_user,
        encapi_db_pass           => $encapi_db_pass,
        git_repository_url       => $git_repository_url,
        git_repository_ssh_key   => $git_repository_ssh_key,
        git_updater_active_host  => $git_updater_active_host,
        acme_certname            => $acme_certname,
        keystone_api_fqdn        => $keystone_api_fqdn,
        token_validator_username => $token_validator_username,
        token_validator_password => $token_validator_password,
        token_validator_project  => $token_validator_project,
    }
}

