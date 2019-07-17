class profile::tendril(
    Hash $ldap_config = lookup('ldap', Hash, hash, {}),
) {
    class { '::tendril':
        site_name    => 'tendril.wikimedia.org',
        docroot      => '/srv/tendril/web',
        ldap_binddn  => 'cn=proxyagent,ou=profile,dc=wikimedia,dc=org',
        ldap_authurl => "ldaps://${ldap_config[ro-server]} ${ldap_config[ro-server-fallback]}/ou=people,dc=wikimedia,dc=org?cn",
        ldap_groups  => [
            'cn=ops,ou=groups,dc=wikimedia,dc=org',
            'cn=nda,ou=groups,dc=wikimedia,dc=org',
            'cn=wmf,ou=groups,dc=wikimedia,dc=org',
        ],
        auth_name    => 'Developer account (use wiki login name not shell) - nda/ops/wmf',
    }
}
