# == Class role::analytics::hue
# Installs Hue server.
#
class role::analytics::hue {
    # Require that all Hue applications
    # have their corresponding clients
    # and configs installed.
    require role::analytics::hadoop::client
    require role::analytics::hive::client
    require role::analytics::oozie::client
    require role::analytics::pig
    require role::analytics::sqoop

    # LDAP Labs config is the same as LDAP in production.
    include ldap::role::config::labs

    if ($::realm == 'production') {
        include passwords::analytics

        $secret_key       = $passwords::analytics::hue_secret_key
        $hive_server_host = 'analytics1027.eqiad.wmnet'
        $ssl_private_key  = '/etc/ssl/private/hue.key'
        $ssl_certificate  = '/etc/ssl/certs/hue.cert'
    }
    elsif ($::realm == 'labs') {
        $secret_key       = 'oVEAAG5dp02MAuIScIetX3NZlmBkhOpagK92wY0GhBbq6ooc0B3rosmcxDg2fJBM'
        # Assume that in Labs, Hue should run on the main master Hadoop NameNode.
        $hive_server_host = $role::analytics::hadoop::config::namenode_hosts[0]
        # Disable ssl in labs.  Labs proxy handles SSL termination.
        $ssl_private_key  = false
        $ssl_certificate  = false
    }

    class { 'cdh::hue':
        hive_server_host       => $hive_server_host,
        secret_key             => $secret_key,
        smtp_host              => $::mail_smarthost[0],
        smtp_from_email        => "hue@${::fqdn}",
        ldap_url               => inline_template('<%= scope.lookupvar("ldap::role::config::labs::servernames").collect { |host| "ldaps://#{host}" }.join(" ") %>'),
        ldap_bind_dn           => $ldap::role::config::labs::ldapconfig['proxyagent'],
        ldap_bind_password     => $ldap::role::config::labs::ldapconfig['proxypass'],
        ldap_base_dn           => $ldap::role::config::labs::basedn,
        ldap_username_pattern  => 'uid=<username>,ou=people,dc=wikimedia,dc=org',
        ldap_user_filter       => 'objectclass=person',
        ldap_user_name_attr    => 'uid',
        ldap_group_filter      => 'objectclass=posixgroup',
        ldap_group_member_attr => 'member',
        # Disable ssl in labs.  Labs proxy handles SSL termination.
        ssl_private_key        => $ssl_private_key,
        ssl_certificate        => $ssl_certificate,
    }
}

# TODO: Hue database backup.
# TODO: Make Hue use MySQL database. Maybe?
