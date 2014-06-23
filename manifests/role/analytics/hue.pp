# == Class role::analytics::hue
# Installs Hue server.
#
class role::analytics::hue {
    # I have to require/include the oozie and hive roles
    # manually here.  I'd rather just make them dependencies
    # of this class, but for some reason, they are not evaluated
    # properly (at least in labs) before cdh4::hue gets evalutated,
    # which causes $cdh4::oozie::url to be undefined.
    require role::analytics::hive::client
    require role::analytics::oozie::client

    # ldap labs config is the same as ldap production.
    include ldap::role::config::labs

    if ($::realm == 'production') {
        include passwords::analytics
        $secret_key         = $passwords::analytics::hue_secret_key
    }
    elsif ($::realm == 'labs') {
        $secret_key         = 'oVEAAG5dp02MAuIScIetX3NZlmBkhOpagK92wY0GhBbq6ooc0B3rosmcxDg2fJBM'
    }

    class { '::cdh4::hue':
        secret_key             => $secret_key,
        smtp_host              => $::mail_smarthost[0]
        smtp_from_email        => "hue@$::fqdn",
        ldap_url               => inline_template('<%= scope.lookupvar("ldap::role::config::labs::servernames").collect { |host| "ldaps://#{host}" }.join(" ") %>'),
        ldap_bind_dn           => $ldap::role::config::labs::ldapconfig['proxyagent'],
        ldap_bind_password     => $ldap::role::config::labs::ldapconfig['proxypass'],
        ldap_base_dn           => $ldap::role::config::labs::basedn,
        ldap_username_pattern  => 'uid=<username>,ou=people,dc=wikimedia,dc=org',
        ldap_user_filter       => 'objectclass=person',
        ldap_user_name_attr    => 'uid',
        ldap_group_filter      => 'objectclass=posixgroup',
        ldap_group_member_attr => 'member',
    }
}

# TODO: Hue database backup.
# TODO: Make Hue use MySQL database.
