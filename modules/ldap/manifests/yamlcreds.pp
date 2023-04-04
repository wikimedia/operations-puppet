# Provision /etc/ldap.yaml file, with credentials for
# readonly access to the labs ldap
class ldap::yamlcreds (
    Hash $ldapconfig,
) {
    $ldap_pw = $ldapconfig['basedn']
    $client_readable_config = {
        'servers'  => $ldapconfig['servernames'],
        'basedn'   => $ldapconfig['basedn'],
        'user'     => "cn=proxyagent,ou=profile,${ldap_pw}",
        'password' => $ldapconfig['proxypass'],
    }

    file { '/etc/ldap.yaml':
        content => to_yaml($client_readable_config),
    }
}
