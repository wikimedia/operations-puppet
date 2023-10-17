# SPDX-License-Identifier: Apache-2.0
class profile::openstack::codfw1dev::pdns::auth::service(
    Array[Hash]         $hosts = lookup('profile::openstack::codfw1dev::pdns::hosts'),
    Array[Stdlib::Fqdn] $designate_hosts = lookup('profile::openstack::codfw1dev::designate_hosts'),
    $db_pass = lookup('profile::openstack::codfw1dev::pdns::db_pass'),
    String $pdns_api_key = lookup('profile::openstack::codfw1dev::pdns::api_key'),
) {
    # We're patching in our ipv4 address for db_host here;
    #  for unclear reasons 'localhost' doesn't work properly
    #  with the version of Mariadb installed on Jessie.
    class {'::profile::openstack::base::pdns::auth::service':
        hosts           => $hosts,
        designate_hosts => $designate_hosts,
        db_pass         => $db_pass,
        db_host         => ipresolve($::fqdn,4),
        pdns_api_key    => $pdns_api_key,
    }
}
