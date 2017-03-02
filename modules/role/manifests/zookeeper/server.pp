# Classes for Zookeeper nodes.
# These role classes will configure Zookeeper properly in either
# the labs or production environments.
#
# Usage:
#
# If you only need Zookeeper client configs to talk to Zookeeper servers:
#   include role::zookeeper::client
#
# If you want to set up a Zookeeper server:
#   include role::zookeeper::server
#
# == Class role::zookeeper::server
#
# zookeeper_cluster_name in hiera will be used to make jmxtrans
# properly prefix zookeeper statsd (and graphite) metrics.
#
# filtertags: labs-project-deployment-prep labs-project-analytics
class role::zookeeper::server {
    include role::zookeeper::client
    $cluster_name = $::role::zookeeper::client::cluster_name

    system::role { 'role::zookeeper::server':
        description => "${cluster_name} Cluster Zookeeper Server"
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
        java_opts           => '-Xms1g -Xmx1g',
    }

    ferm::service { 'zookeeper':
        proto  => 'tcp',
        # Zookeeper client, protocol ports
        port   => '(2181 2182 2183)',
        srange => '$DOMAIN_NETWORKS',
    }

    $group_prefix = "zookeeper.cluster.${cluster_name}."
    # Use jmxtrans for sending metrics to ganglia
    class { 'zookeeper::jmxtrans':
        group_prefix => $group_prefix,
        statsd       => hiera('statsd', undef),
    }

    if $::realm == 'production' {
        # Configure service pages via hiera.
        $zookeeper_cluster_is_critical = hiera('zookeeper_cluster_is_critical', false)

        # Alert if Zookeeper Server is not running.
        nrpe::monitor_service { 'zookeeper':
            description  => 'Zookeeper Server',
            nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a "org.apache.zookeeper.server.quorum.QuorumPeerMain /etc/zookeeper/conf/zoo.cfg"',
            critical     => $zookeeper_cluster_is_critical,
        }

        # jmxtrans statsd writer emits fqdns in keys
        # by substituting '.' with '_' and suffixing the jmx port.
        $graphite_broker_key = regsubst("${::fqdn}_${::zookeeper::jmxtrans::jmx_port}", '\.', '_', 'G')

        # Alert if NumAliveConnections approaches max client connections
        # Alert if any Kafka Broker replica lag is too high
        monitoring::graphite_threshold { 'zookeeper-client-connections':
            description => 'Zookeeper Alive Client Connections too high',
            metric      => "${group_prefix}zookeeper.${graphite_broker_key}.zookeeper.NumAliveConnections",
            # Warn if we go over 50% of max
            warning     => $::zookeeper::max_client_connections * 0.5,
            # Critical if we go over 90% of max
            critical    => $::zookeeper::max_client_connections * 0.9,
        }

        # Experimental Analytics alarms on JVM usage
        # These alarms are not really generic and the thresholds are based
        # on a fixed Max Heap size of 1G.
        monitoring::graphite_threshold { 'zookeeper-server-heap-usage':
            description   => 'Zookeeper node JVM Heap usage',
            metric        => "${group_prefix}jvm_memory.${::hostname}_eqiad_wmnet_${::zookeeper::jmxtrans::jmx_port}.memory.HeapMemoryUsage_used.upper",
            from          => '60min',
            warning       => '921',  # 90% of the Heap used
            critical      => '972',  # 95% of the Heap used
            percentage    => '60',
            contact_group => 'analytics',
        }
    }
}
