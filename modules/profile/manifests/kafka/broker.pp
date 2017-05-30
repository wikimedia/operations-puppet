# == Class profile::kafka::broker
# Sets up a Kafka broker instance belonging to the $kafka_cluster_name
# cluster.  $kafka_cluster_name must have an entry in the hiera 'kafka_clusters'
# variable, and $::fqdn must be listed as a broker there.
#
# == Parameters
# [*kafka_cluster_name*]
#   Kafka cluster name.  This should be the non DC/project suffixed cluster name,
#   e.g. main, aggregate, simple, etc.  The kafka_cluster_name puppet parser
#   function will determine the proper full cluster name based on $::realm
#   and/or $::labsproject.  Hiera: kafka_cluster_name
#
# [*statsd*]
#   Statsd URI to use for metrics.  Hiera: statsd
#
# [*plaintext*]
#   Boolean whether to use a plaintext listener on port 9092.
#   Hieara: profile::kafka::broker::plaintext
#
# [*tls_secrets_path*]
#   Relative base path to tls secrets files in operations puppet private repository.
#   If set, TLS/SSL will be configured for Kafka.  Each broker needs to have
#   a ca-manager created directory for the node's $::fqdn in this path.
#   E.g. if this is set to 'kafka/common', and the current node is kafka1101.eqiad.wmnet,
#   then modules/secret/secrets/kafka/common/kafka1101.eqiad.wmnet/ should exist
#   and should contain keyfiles and keystores created by ca-manager.
#   Hiera: 'profile::kafka::broker::tls_secrets_path'
#
# [*tls_key_password*]
#   Password for keystores and keys in tls_secrets_path.  You should
#   set this in hiera in the operations puppet private repository.
#   Hiera: profile::kafka::broker::tls_key_password
#
# [*log_dirs*]
#   Array of Kafka log data directories.  The confluent::kafka::broker class
#   manages these directories but not anything above them.
#   You must ensure that any parent directories exist outside of this class.
#   Hiera: profile::kafka::broker::log_dirs
#
# [*auto_leader_rebalance_enable*]
#   Hiera: profile::kafka::broker::auto_leader_rebalance_enable
#
# [*log_retention_hours*]
#   Hiera: profile::kafka::broker::log_retention_hours
#
# [*num_replica_fetchers*]
#   Hiera: profile::kafka::broker::num_replica_fetchers
#
# [*nofiles_ulimit*]
#   Hiera: profile::kafka::broker::nofiles_ulimit
#
# [*replica_maxlag_warning*]
#   Max messages a replica can lag before a warning alert is generated.
#   Hiera: profile::kafka::broker::replica_maxlag_warning
#
# [*replica_maxlag_critical*]
#   Mac messages a replica can lag before a critical alert is generated.
#   Hiera: profile::kafka::broker::replica_maxlag_critical
#
class profile::kafka::broker(
    $kafka_cluster_name           = hiera('kafka_cluster_name'),
    $statsd                       = hiera('statsd'),

    $plaintext                    = hiera('profile::kafka::broker::plaintext'),
    $tls_secrets_path             = hiera('profile::kafka::broker::tls_secrets_path'),
    $tls_key_password             = hiera('profile::kafka::broker::tls_key_password'),

    $log_dirs                     = hiera('profile::kafka::broker::log_dirs'),
    $auto_leader_rebalance_enable = hiera('profile::kafka::broker::auto_leader_rebalance_enable'),
    $log_retention_hours          = hiera('profile::kafka::broker::log_retention_hours'),
    $num_replica_fetchers         = hiera('profile::kafka::broker::num_replica_fetchers'),
    $nofiles_ulimit               = hiera('profile::kafka::broker::nofiles_ulimit'),
    $replica_maxlag_warning       = hiera('profile::kafka::broker::replica_maxlag_warning'),
    $replica_maxlag_critical      = hiera('profile::kafka::broker::replica_maxlag_critical'),
) {
    $config         = kafka_config($kafka_cluster_name)
    $cluster_name   = $config['name']
    $zookeeper_url  = $config['zookeeper']['url']
    $brokers_string = $config['brokers']['string']

    require_package('openjdk-8-jdk')

    # kafkacat is handy!
    require_package('kafkacat')

    $plaintext_port = 9092
    $plaintext_listener = "PLAINTEXT://:${plaintext_port}"
    $tls_port = 9093
    $tls_listener = "SSL://:${tls_port}"

    # Conditionally set $listeners and $ssl_client_auth
    # based on values of $tls and $plaintext.
    if $tls_secrets_path and $plaintext {
        $listeners = [$plaintext_listener, $tls_listener]
        $ssl_client_auth       = 'requested'
    }
    elsif $plaintext {
        $listeners             = [$plaintext_listener]
        $ssl_client_auth       = 'none'
    }
    elsif $tls_secrets_path {
        $listeners             = [$tls_listener]
        $ssl_client_auth       = 'required'
    }
    else {
        fatal('Must set at least one of $plaintext or $ssl to true.')
    }

    if $tls_secrets_path {
        # Distribute the Java keystores for this broker's certificate.
        # These need to have been generated with ca-manager and
        # checked into the Puppet private repo in
        # modules/secret/secrets/$tls_secrets_path/$fqdn/.
        ::ca::certs { "${tls_secrets_path}/${::fqdn}":
            destination => '/etc/kafka/tls',
            owner       => 'kafka',
        }

        $security_inter_broker_protocol = 'SSL'
        $ssl_keystore_location          = "/etc/kafka/tls/${::fqdn}.jks"
        $ssl_keystore_password          = $tls_key_password
        $ssl_key_password               = $tls_key_password
        $ssl_truststore_location        = '/etc/kafka/tls/truststore.jks'
        $ssl_truststore_password        = $tls_key_password
    }
    else {
        $security_inter_broker_protocol = undef
        $ssl_keystore_location          = undef
        $ssl_keystore_password          = undef
        $ssl_key_password               = undef
        $ssl_truststore_location        = undef
        $ssl_truststore_password        = undef
    }

    class { '::confluent::kafka::client':
        # TODO: These should be removed once they are
        # the default in ::confluent::kafka module
        scala_version => '2.11',
        kafka_version => '0.10.2.1-1',
        java_home     => '/usr/lib/jvm/java-1.8.0-openjdk-amd64',
    }

    class { '::confluent::kafka::broker':
        log_dirs                       => $log_dirs,
        brokers                        => $config['brokers']['hash'],
        zookeeper_connect              => $config['zookeeper']['url'],
        nofiles_ulimit                 => $nofiles_ulimit,
        default_replication_factor     => min(3, $config['brokers']['size']),

        # TODO: This can be removed once it is a default
        # in ::confluent::kafka module
        inter_broker_protocol_version  => '0.10.2',
        # Use Kafka/LinkedIn recommended settings with G1 garbage collector.
        # https://kafka.apache.org/documentation/#java
        # Note that MetaspaceSize is a Java 8 setting.
        jvm_performance_opts           => '-server -XX:MetaspaceSize=96m -XX:+UseG1GC -XX:MaxGCPauseMillis=20 -XX:InitiatingHeapOccupancyPercent=35 -XX:G1HeapRegionSize=16M -XX:MinMetaspaceFreeRatio=50 -XX:MaxMetaspaceFreeRatio=80',

        listeners                      => $listeners,

        security_inter_broker_protocol => $security_inter_broker_protocol,
        ssl_keystore_location          => $ssl_keystore_location,
        ssl_keystore_password          => $ssl_keystore_password,
        ssl_key_password               => $ssl_key_password,
        ssl_truststore_location        => $ssl_truststore_location,
        ssl_truststore_password        => $ssl_truststore_password,
        ssl_client_auth                => $ssl_client_auth,

        auto_leader_rebalance_enable   => $auto_leader_rebalance_enable,
        num_replica_fetchers           => $num_replica_fetchers,
    }

    class { '::confluent::kafka::broker::jmxtrans':
        # Cluster metrics prefix for graphite, etc.
        group_prefix => "kafka.cluster.${cluster_name}.",
        statsd       => $statsd,
    }

    class { '::confluent::kafka::broker::alerts':
        replica_maxlag_warning  => $replica_maxlag_warning,
        replica_maxlag_critical => $replica_maxlag_critical,
    }

    $ferm_plaintext_ensure = $plaintext ? {
        false => 'absent',
        undef => 'absent',
        true  => 'present',
    }
    # Firewall for Kafka broker on $plaintext
    ferm::service { 'kafka-broker-plaintext':
        ensure  => $ferm_plaintext_ensure,
        proto   => 'tcp',
        port    => $plaintext_port,
        notrack => true,
        srange  => '($PRODUCTION_NETWORKS $FRACK_NETWORKS)',
    }

    $ferm_tls_ensure = $tls_secrets_path ? {
        false   => 'absent',
        undef   => 'absent',
        default => 'present'
    }
    # Firewall for Kafka broker on $tls_port
    ferm::service { 'kafka-broker-tls':
        ensure  => $ferm_tls_ensure,
        proto   => 'tcp',
        port    => $tls_port,
        notrack => true,
        srange  => '($PRODUCTION_NETWORKS $FRACK_NETWORKS)',
    }

    # In case of mediawiki spikes we've been seeing up to 300k connections,
    # so raise the connection table size on Kafka brokers (default is 256k)
    sysctl::parameters { 'kafka_conntrack':
        values   => {
            'net.netfilter.nf_conntrack_max' => 524288,
        },
        priority => 75,
    }
    # Monitor TCP Connection States
    diamond::collector { 'TcpConnStates':
        source => 'puppet:///modules/diamond/collector/tcpconnstates.py',
    }
    # Monitor Ferm/Netfilter Connection Flows
    diamond::collector { 'NfConntrackCount':
        source => 'puppet:///modules/diamond/collector/nf_conntrack_counter.py',
    }
}
