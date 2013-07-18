# == Class role::analytics::hue
# Installs Hue server.
#
class role::analytics::hue {
    include passwords::analytics

    if ($::realm == 'production') {
        include passwords::ldap::production
        $ldap_bind_password = $passwords::ldap::production::proxypass
    }
    elsif ($::realm == 'labs') {
        include passwords::ldap::labs
        $ldap_bind_password = $passwords::ldap::labs::proxypass
    }

    # TODO: use a non self signed cert for SSL.
    class { '::cdh4::hue':
        secret_key             => $passwords::analytics::hue_secret_key,
        smtp_host              => 'mchenry.wikimedia.org',
        smtp_from_email        => "hue@$::fqdn",
        # TODO:  Are these the right hosts for labs LDAP?
        #        Don't hard code these if possible.
        ldap_url               => 'ldaps://virt0.wikimedia.org ldaps://virt1000.wikimedia.org',
        ldap_bind_dn           => 'cn=proxyagent,ou=profile,dc=wikimedia,dc=org',
        ldap_bind_password     => $ldap_bind_password,
        ldap_base_dn           => 'dc=wikimedia,dc=org',
        ldap_username_pattern  => 'uid=<username>,ou=people,dc=wikimedia,dc=org',
        ldap_user_filter       => 'objectclass=person',
        ldap_user_name_attr    => 'uid',
        ldap_group_filter      => 'objectclass=posixgroup',
        ldap_group_member_attr => 'member',
    }
}

# TODO: Hue SQLite database backup.
