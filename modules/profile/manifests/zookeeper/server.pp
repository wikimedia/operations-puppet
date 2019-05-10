# == Class profile::zookeeper::server
#
# zookeeper_cluster_name in hiera will be used to make jmxtrans
# properly prefix zookeeper statsd (and graphite) metrics.
#
# filtertags: labs-project-deployment-prep labs-project-analytics
class profile::zookeeper::server (
    $clusters               = hiera('zookeeper_clusters'),
    $cluster_name           = hiera('profile::zookeeper::cluster_name'),
    $version                = hiera('profile::zookeeper::zookeeper_version'),
    $max_client_connections = hiera('profile::zookeeper::max_client_connections', 1024),
    $sync_limit             = hiera('profile::zookeeper::sync_limit', 8),
    $monitoring_enabled     = hiera('profile::zookeeper::monitoring_enabled', false),
    $is_critical            = hiera('profile::zookeeper::is_critical', false),
    $prometheus_instance    = hiera('profile::zookeeper::prometheus_instance', 'ops'),
) {

    require_package('default-jdk')

    if $monitoring_enabled {
        require ::profile::zookeeper::monitoring::server
        $extra_java_opts = $::profile::zookeeper::monitoring::server::java_opts
    } else {
        $extra_java_opts = ''
    }

    # The zookeeper349 component for jessie-wikimedia has been created to
    # support a more flexible transition to Debian Stretch.
    if $version == '3.4.9-3~jessie' {
        if os_version('debian == jessie') {
            apt::repository { 'wikimedia-zookeeper349':
                uri        => 'http://apt.wikimedia.org/wikimedia',
                dist       => 'jessie-wikimedia',
                components => 'component/zookeeper349',
                before     => [
                    Package['zookeeperd'],
                    Package['zookeeper'],
                ],
            }
        } else {
            fail('Zookeeper 3.4.9-3~jessie should be installed only on Debian Jessie.')
        }
    }

    class { '::zookeeper':
        hosts                  => $clusters[$cluster_name]['hosts'],
        version                => $version,
        sync_limit             => $sync_limit,
        max_client_connections => $max_client_connections,
    }

    class { '::zookeeper::server':
        # If zookeeper runs in environments where JAVA_TOOL_OPTIONS is defined,
        # (like all the analytics hosts after T128295)
        # the zkCleanup.sh script will cause cronspam to root@ due to
        # message like the following to stderr:
        # 'Picked up JAVA_TOOL_OPTIONS: -Dfile.encoding=UTF-8'
        # There seems to be no elegant way to avoid the JVM spam,
        # so until somebody finds a better way we redirect stdout to /dev/null
        # and we filter out JAVA_TOOL_OPTIONS messages from stderr.
        cleanup_script_args => '-n 10 2>&1 > /dev/null | grep -v JAVA_TOOL_OPTIONS',
        java_opts           => "-Xms1g -Xmx1g ${extra_java_opts}",
    }

    if $monitoring_enabled {
        # Alert if Zookeeper Server is not running.
        nrpe::monitor_service { 'zookeeper':
            description  => 'Zookeeper Server',
            nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a "org.apache.zookeeper.server.quorum.QuorumPeerMain /etc/zookeeper/conf/zoo.cfg"',
            critical     => $is_critical,
            notes_url    => 'https://wikitech.wikimedia.org/wiki/Zookeeper',
        }

        monitoring::check_prometheus { 'zookeeper_client_conns':
            description     => 'Zookeeper Alive Client Connections too high',
            query           => "scalar(org_apache_ZooKeeperService_NumAliveConnections{instance=\"${::hostname}:12181\", zookeeper_cluster=\"${cluster_name}\"})",
            prometheus_url  => "http://prometheus.svc.${::site}.wmnet/${prometheus_instance}",
            warning         => $max_client_connections / 2,
            critical        => $max_client_connections,
            method          => 'ge',
            dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/zookeeper?refresh=5m&orgId=1&panelId=6&fullscreen'],
            notes_link      => 'https://wikitech.wikimedia.org/wiki/Zookeeper',
        }

        # Experimental Analytics alarms on JVM usage
        # These alarms are not really generic and the thresholds are based
        # on a fixed Max Heap size of 1G.
        monitoring::check_prometheus { 'zookeeper-server-heap-usage':
            description     => 'Zookeeper node JVM Heap usage',
            dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/zookeeper?refresh=5m&orgId=1&panelId=40&fullscreen'],
            query           => "scalar(avg_over_time(jvm_memory_bytes_used{instance=\"${::hostname}:12181\",area=\"heap\"}[60m])/avg_over_time(jvm_memory_bytes_max{instance=\"${::hostname}:12181\",area=\"heap\"}[60m]))",
            warning         => 0.9,
            critical        => 0.95,
            contact_group   => 'analytics',
            prometheus_url  => "http://prometheus.svc.${::site}.wmnet/${prometheus_instance}",
            notes_link      => 'https://wikitech.wikimedia.org/wiki/Zookeeper',
        }
    }
}
