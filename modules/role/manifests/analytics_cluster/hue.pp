# == Class role::analytics_cluster::hue
# Installs Hue server.
#
class role::analytics_cluster::hue {
    system::role { 'analytics_cluster::hue':
        description => 'Hue (Hadoop User Experience) WebGUI',
    }

    # Require that all Hue applications
    # have their corresponding clients
    # and configs installed.
    # Include Hadoop ecosystem client classes.
    require role::analytics_cluster::hadoop::client,
        role::analytics_cluster::hive::client,
        role::analytics_cluster::oozie::client,
        # These don't require any extra configuration,
        # so no role class is needed.
        cdh::pig,
        cdh::sqoop,
        cdh::mahout,
        cdh::spark

    # LDAP Labs config is the same as LDAP in production.
    include ldap::role::config::labs

    class { 'cdh::hue':
        # We always host hive-server on the same node as hive-metastore.
        hive_server_host           => hiera('cdh::hive::metastore_host'),
        smtp_host                  => $::mail_smarthost[0],
        smtp_from_email            => "hue@${::fqdn}",
        ldap_url                   => inline_template('<%= scope.lookupvar("ldap::role::config::labs::servernames").collect { |host| "ldaps://#{host}" }.join(" ") %>'),
        ldap_bind_dn               => $ldap::role::config::labs::ldapconfig['proxyagent'],
        ldap_bind_password         => $ldap::role::config::labs::ldapconfig['proxypass'],
        ldap_base_dn               => $ldap::role::config::labs::basedn,
        ldap_username_pattern      => 'uid=<username>,ou=people,dc=wikimedia,dc=org',
        ldap_user_filter           => 'objectclass=person',
        ldap_user_name_attr        => 'uid',
        ldap_group_filter          => 'objectclass=posixgroup',
        ldap_group_member_attr     => 'member',
        # ldap_create_users_on_login => $ldap_create_users_on_login,
        # Disable hue's SSL.  SSL terminiation is handled by an upstream proxy.
        ssl_private_key            => false,
        ssl_certificate            => false,
        secure_proxy_ssl_header    => true,
    }

    ferm::service{ 'hue_server':
        proto  => 'tcp',
        port   => '8888',
        srange => '$INTERNAL',
    }
}

# TODO: Hue database backup.
# TODO: Make Hue use MySQL database. Maybe?
