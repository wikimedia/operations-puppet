# Provision /etc/ldap.yaml file, with credentials for
# readonly access to the labs ldap
class ldap::yamlcreds {
    include ::ldap::config::labs

    $ldapconfig = $::ldap::config::labs::ldapconfig

    $ldap_pw = $ldapconfig['basedn']
    $client_readable_config = {
        'servers'  => $ldapconfig['servernames'],
        'basedn'   => $ldapconfig['basedn'],
        'user'     => "cn=proxyagent,ou=profile,${ldap_pw}",
        'password' => $ldapconfig['proxypass'],
    }

    file { '/etc/ldap.yaml':
        content => ordered_yaml($client_readable_config),
    }
}
