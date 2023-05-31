# SPDX-License-Identifier: Apache-2.0
# @summary provisions the ldap client configuration file
# @param $servers servers to connect to
# @param $base_dn base dn of the ldap tree
# @param $proxy_pass password for the cn=proxyagent user
class ldap::client::config (
    Array[Stdlib::Host] $servers,
    String[1]           $base_dn,
    String[1]           $proxy_pass,
) {
    file { '/etc/ldap/ldap.conf':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('ldap/client/config/ldap.conf.erb'),
    }
}
