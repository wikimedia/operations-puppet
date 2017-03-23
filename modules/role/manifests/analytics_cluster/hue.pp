# == Class role::analytics_cluster::hue
# Installs Hue server.
#
# filtertags: labs-project-analytics
class role::analytics_cluster::hue {
    system::role { 'analytics_cluster::hue':
        description => 'Hue (Hadoop User Experience) WebGUI',
    }

    # Include Wikimedia's thirdparty/cloudera apt component
    # as an apt source on all Hadoop hosts.  This is needed
    # to install CDH packages from our apt repo mirror.
    require ::role::analytics_cluster::apt

    # Require that all Hue applications
    # have their corresponding clients
    # and configs installed.
    # Include Hadoop ecosystem client classes.
    require ::role::analytics_cluster::hadoop::client
    require ::role::analytics_cluster::hive::client
    require ::role::analytics_cluster::oozie::client
    # These don't require any extra configuration,
    # so no role class is needed.
    require ::cdh::pig
    require ::cdh::sqoop
    require ::cdh::mahout
    require ::cdh::spark

    # LDAP Labs config is the same as LDAP in production.
    include ::ldap::role::config::labs

    class { '::cdh::hue':
        # We always host hive-server on the same node as hive-metastore.
        hive_server_host        => hiera('cdh::hive::metastore_host'),
        smtp_host               => $::mail_smarthost[0],
        smtp_from_email         => "hue@${::fqdn}",
        ldap_url                => inline_template('<%= scope.lookupvar("ldap::role::config::labs::servernames").collect { |host| "ldaps://#{host}" }.join(" ") %>'),
        ldap_bind_dn            => $ldap::role::config::labs::ldapconfig['proxyagent'],
        ldap_bind_password      => $ldap::role::config::labs::ldapconfig['proxypass'],
        ldap_base_dn            => $ldap::role::config::labs::basedn,
        ldap_username_pattern   => 'uid=<username>,ou=people,dc=wikimedia,dc=org',
        ldap_user_filter        => 'objectclass=person',
        ldap_user_name_attr     => 'uid',
        ldap_group_filter       => 'objectclass=posixgroup',
        ldap_group_member_attr  => 'member',
        # ldap_create_users_on_login => $ldap_create_users_on_login,
        # Disable hue's SSL.  SSL terminiation is handled by an upstream proxy.
        ssl_private_key         => false,
        ssl_certificate         => false,
        secure_proxy_ssl_header => true,
    }

    ferm::service{ 'hue_server':
        proto  => 'tcp',
        port   => '8888',
        srange => '$PRODUCTION_NETWORKS',
    }

    # Include icinga alerts if production realm.
    if $::realm == 'production' {
        nrpe::monitor_service { 'hue':
            description   => 'Hue Server',
            nrpe_command  => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C python2.7 -a "/usr/lib/hue/build/env/bin/hue"',
            contact_group => 'admins,analytics',
            require       => Class['cdh::hue'],
        }
    }
}

# TODO: Hue database backup.
# TODO: Make Hue use MySQL database. Maybe?
