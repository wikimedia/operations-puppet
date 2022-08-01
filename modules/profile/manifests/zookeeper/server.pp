# == Class profile::zookeeper::server
#
# zookeeper_cluster_name in hiera will be used to make jmxtrans
# properly prefix zookeeper statsd (and graphite) metrics.
#
class profile::zookeeper::server (
    Hash $clusters                       = lookup('zookeeper_clusters'),
    String $cluster_name                 = lookup('profile::zookeeper::cluster_name'),
    Integer $max_client_connections      = lookup('profile::zookeeper::max_client_connections', {default_value => 1024}),
    Integer $sync_limit                  = lookup('profile::zookeeper::sync_limit', {default_value => 8}),
    Boolean $monitoring_enabled          = lookup('profile::zookeeper::monitoring_enabled', {default_value => false}),
    String $monitoring_contact_group     = lookup('profile::zookeeper::monitoring_contact_group', {default_value => 'admins'}),
    Boolean $is_critical                 = lookup('profile::zookeeper::is_critical', {default_value => false}),
    String $prometheus_instance          = lookup('profile::zookeeper::prometheus_instance', {default_value => 'ops'}),
    Optional[Stdlib::Unixpath] $override_java_home = lookup('profile::zookeeper::override_java_home', {default_value => undef }),
){
    require profile::java
    require profile::zookeeper::monitoring::server
    $extra_java_opts = $profile::zookeeper::monitoring::server::java_opts

    $java_home = pick($override_java_home, $profile::java::default_java_home)

    # Safety check to avoid that Zookeeper runs on java 8 with Buster,
    # since it will not work (jars are built using java 11).
    if debian::codename::eq('buster') and !('11' in $java_home) {
        fail('Zookeeper on buster needs to run with Java 11, please use $override_java_home.')
    }

    class { 'zookeeper':
        hosts                  => $clusters[$cluster_name]['hosts'],
        sync_limit             => $sync_limit,
        max_client_connections => $max_client_connections,
    }

    class { 'zookeeper::server':
        cleanup_script_args => '-n 10',
        java_opts           => "-Xms1g -Xmx1g ${extra_java_opts}",
        java_home           => $java_home,
    }

    if $monitoring_enabled {
        # Alert if Zookeeper Server is not running.
        nrpe::monitor_service { 'zookeeper':
            description   => 'Zookeeper Server',
            nrpe_command  => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a "org.apache.zookeeper.server.quorum.QuorumPeerMain /etc/zookeeper/conf/zoo.cfg"',
            critical      => $is_critical,
            contact_group => $monitoring_contact_group,
            notes_url     => 'https://wikitech.wikimedia.org/wiki/Zookeeper',
        }

        monitoring::check_prometheus { 'zookeeper_client_conns':
            description     => 'Zookeeper Alive Client Connections too high',
            query           => "scalar(org_apache_ZooKeeperService_NumAliveConnections{instance=\"${::hostname}:12181\", zookeeper_cluster=\"${cluster_name}\"})",
            prometheus_url  => "http://prometheus.svc.${::site}.wmnet/${prometheus_instance}",
            warning         => $max_client_connections / 2,
            critical        => $max_client_connections,
            method          => 'ge',
            contact_group   => $monitoring_contact_group,
            dashboard_links => ['https://grafana.wikimedia.org/d/000000261/zookeeper?orgId=1&refresh=5m&viewPanel=6'],
            notes_link      => 'https://wikitech.wikimedia.org/wiki/Zookeeper',
        }
    }
}
