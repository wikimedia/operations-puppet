# == Class profile::hue
#
# Installs Hue server.
#
class profile::hue (
    $hive_server_host           = hiera('profile::hue::hive_server_host'),
    $database_host              = hiera('profile::hue::database_host'),
    $database_engine            = hiera('profile::hue::database_engine', 'mysql'),
    $database_user              = hiera('profile::hue::database_user', 'hue'),
    $database_port              = hiera('profile::hue::database_port', 3306),
    $database_name              = hiera('profile::hue::database_name', 'hue'),
    $ldap_create_users_on_login = hiera('profile::hue::ldap_create_users_on_login', false),
    $monitoring_enabled         = hiera('profile::hue::monitoring_enabled', false),
){

    # Require that all Hue applications
    # have their corresponding clients
    # and configs installed.
    # Include Hadoop ecosystem client classes.
    require ::profile::hadoop::common
    require ::profile::hive::client
    require ::profile::oozie::client

    # These don't require any extra configuration,
    # so no role class is needed.
    class { '::cdh::pig': }
    class { '::cdh::sqoop': }
    class { '::cdh::mahout': }
    class { '::cdh::spark': }

    # LDAP Labs config is the same as LDAP in production.
    class { '::ldap::config::labs': }

    class { '::cdh::hue':
        # We always host hive-server on the same node as hive-metastore.
        hive_server_host           => $hive_server_host,
        smtp_host                  => $::mail_smarthost[0],
        database_host              => $database_host,
        database_user              => $database_user,
        database_engine            => $database_engine,
        database_name              => $database_name,
        database_port              => $database_port,
        smtp_from_email            => "hue@${::fqdn}",
        ldap_url                   => inline_template('<%= scope.lookupvar("::ldap::config::labs::servernames").collect { |host| "ldaps://#{host}" }.join(" ") %>'),
        ldap_bind_dn               => $::ldap::config::labs::ldapconfig['proxyagent'],
        ldap_bind_password         => $::ldap::config::labs::ldapconfig['proxypass'],
        ldap_base_dn               => $::ldap::config::labs::basedn,
        ldap_username_pattern      => 'uid=<username>,ou=people,dc=wikimedia,dc=org',
        ldap_user_filter           => 'objectclass=person',
        ldap_user_name_attr        => 'uid',
        ldap_group_filter          => 'objectclass=posixgroup',
        ldap_group_member_attr     => 'member',
        ldap_create_users_on_login => $ldap_create_users_on_login,
        # Disable hue's SSL.  SSL terminiation is handled by an upstream proxy.
        ssl_private_key            => false,
        ssl_certificate            => false,
        secure_proxy_ssl_header    => true,
    }

    ferm::service{ 'hue_server':
        proto  => 'tcp',
        port   => '8888',
        srange => '$PRODUCTION_NETWORKS',
    }

    # Include icinga alerts if production realm.
    if $monitoring_enabled {
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
