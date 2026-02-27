# SPDX-License-Identifier: Apache-2.0
# == Class profile::zookeeper::server
#
class profile::zookeeper::server (
    Hash $clusters                       = lookup('zookeeper_clusters'),
    String $cluster_name                 = lookup('profile::zookeeper::cluster_name'),
    Integer $max_client_connections      = lookup('profile::zookeeper::max_client_connections', {default_value => 1024}),
    Integer $sync_limit                  = lookup('profile::zookeeper::sync_limit', {default_value => 8}),
    Boolean $enable_tls                  = lookup('profile::zookeeper::enable_tls', {default_value => false}),
    Optional[Stdlib::Unixpath] $tls_keystore = lookup('profile::zookeeper::tls_keystore', {default_value => undef }),
    Optional[Stdlib::Unixpath] $tls_truststore = lookup('profile::zookeeper::tls_truststore', {default_value => undef }),
    Optional[String] $tls_password       = lookup('profile::zookeeper::tls_password', {default_value => undef }),
    Boolean $monitoring_enabled          = lookup('profile::zookeeper::monitoring_enabled', {default_value => false}),
    String $monitoring_contact_group     = lookup('profile::zookeeper::monitoring_contact_group', {default_value => 'admins'}),
    Boolean $is_critical                 = lookup('profile::zookeeper::is_critical', {default_value => false}),
    String $prometheus_instance          = lookup('profile::zookeeper::prometheus_instance', {default_value => 'ops'}),
    Optional[Stdlib::Unixpath] $override_java_home = lookup('profile::zookeeper::override_java_home', {default_value => undef }),
    Optional[String] $extra_java_opts    = lookup('profile::zookeeper::server::extra_java_opts', {default_value => undef }),
){
    require profile::java
    require profile::zookeeper::monitoring::server

    if $extra_java_opts {
        $extra_java_opts_ = "${profile::zookeeper::monitoring::server::java_opts} ${extra_java_opts}"
    } else {
        $extra_java_opts_ = $profile::zookeeper::monitoring::server::java_opts
    }

    $java_home = pick($override_java_home, $profile::java::default_java_home)

    class { 'zookeeper':
        hosts                  => $clusters[$cluster_name]['hosts'],
        sync_limit             => $sync_limit,
        max_client_connections => $max_client_connections,
        enable_tls             => $enable_tls,
        tls_keystore           => $tls_keystore,
        tls_truststore         => $tls_truststore,
        tls_password           => $tls_password,
    }

    class { 'zookeeper::server':
        cleanup_script_args => '-n 10',
        java_opts           => "-Xms1g -Xmx1g ${extra_java_opts_}",
        java_home           => $java_home,
        enable_tls          => $enable_tls,
    }

    if $monitoring_enabled {
        # Alert if Zookeeper Server is not running.
        nrpe::monitor_service { 'zookeeper':
            description         => 'Zookeeper Server',
            nrpe_command        => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a "org.apache.zookeeper.server.quorum.QuorumPeerMain /etc/zookeeper/conf/zoo.cfg"',
            critical            => $is_critical,
            contact_group       => $monitoring_contact_group,
            notes_url           => 'https://wikitech.wikimedia.org/wiki/Zookeeper',
            migration_task      => 'T309012',
            enable_icinga_check => false,
        }
    }
}
