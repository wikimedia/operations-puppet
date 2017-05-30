# == Class profile::kafka::broker
# Sets up a Kafka broker instance belonging to the $kafka_cluster_name
# cluster.  $kafka_cluster_name must have an entry in the hiera 'kafka_clusters'
# variable, and $::fqdn must be listed as a broker there.
#
class profile::kafka::broker(
    $kafka_cluster_name           = hiera('kafka_cluster_name')
    $statsd                       = hiera('statsd'),
    $log_dirs                     = hiera('profile::kafka::broker::log_dirs'),
    $plaintext                    = hiera('profile::kafka::broker::plaintext'),
    $tls                          = hiera('profile::kafka::broker::tls'),
    $tls_key_password             = hiera('profile::kafka::broker::tls_key_password'),
    $auto_leader_rebalance_enable = hiera('profile::kafka::broker::auto_leader_rebalance_enable'),
    $log_retention_hours          = hiera('profile::kafka::broker::log_retention_hours),
    $num_replica_fetchers         = hiera('profile::kafka::broker::num_replica_fetchers),
    $nofiles_ulimit               = hiera('profile::kafka::broker::nofiles_ulimit'),
    $replica_maxlag_warning       = hiera('profile::kafka::broker::replica_maxlag_warning'),
    $replica_maxlag_critical      = hiera('profile::kafka::broker::replica_maxlag_critical'),
) {
    $config         = kafka_config($kafka_cluster_name)
    $cluster_name   = $config['name']
    $zookeeper_url  = $config['zookeeper']['url']
    $brokers_string = $config['brokers']['string']

    system::role { 'profile::kafka::broker':
        description => "Kafka Broker in the ${cluster_name} cluster",
    }

    require_package('openjdk-8-jdk')

    # kafkacat is handy!
    require_package('kafkacat')

    $plaintext_port = 9092
    $plaintext_listener = "PLAINTEXT://:${plaintext_port}"
    $tls_port = 9093
    $tls_listener = "SSL://:${tls_port}"

    # Conditionally set $listeners and $ssl_client_auth
    # based on values of $tls and $plaintext.
    if $tls and $plaintext {
        $listeners = [$plaintext_listener, $tls_listener]
        $ssl_client_auth       = 'requested'
        $ferm_tls_ensure       = 'present'
        $ferm_plaintext_ensure = 'present'
    }
    else if $plaintext {
        $listeners             = [$plaintext_listener]
        $ssl_client_auth       = 'none'
        $ferm_tls_ensure       = 'absent'
        $ferm_plaintext_ensure = 'present'
    }
    else if $tls {
        $listeners             = [$tls_listener]
        $ssl_client_auth       = 'required'
        $ferm_tls_ensure       = 'present'
        $ferm_plaintext_ensure = 'absent'
    }
    else {
        fatal('Must set at least one of $plaintext or $ssl to true.')
    }

    if $tls {
        # Distribute the Java keystores for this broker's certificate.
        # These need to have been generated with ca-manager and
        # checked into the Puppet private repo in
        # modules/secret/secrets/kafka/$cluster_name/$fqdn/.
        # Note that $cluster_name is the full cluster name, including
        # DC suffix, e.g. aggregate-eqiad, main-codfw, etc.
        ::ca::certs { "kafka/${cluster_name}/${::fqdn}":
            destination => '/etc/kafka/tls',
            owner       => 'kafka',
        }

        $security_inter_broker_protocol = 'SSL'
        $ssl_keystore_location          = "/etc/kafka/tls/${::fqdn}.jks"
        $ssl_keystore_password          = $tls_key_password
        $ssl_key_password               = $tls_key_password
        $ssl_truststore_location        = "/etc/kafka/tls/truststore.jks"
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

    file { $log_dirs:
        ensure => 'directory',
        owner  => 'kafka',
        group  => 'kafka',
        mode   => '0755',
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
        default_replication_factor     => min(3, $config['brokers']['size'])

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
        num_replica_fetchers            => $num_replica_fetchers,
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
        true  => 'present',
        false => 'absent',
    }
    # Firewall for Kafka broker on $plaintext
    ferm::service { 'kafka-broker-plaintext':
        proto   => 'tcp',
        port    => $plaintext_port,
        notrack => true,
        srange  => '($PRODUCTION_NETWORKS $FRACK_NETWORKS)',
        ensure  => $ferm_plaintext_ensure,
    }

    $ferm_tls_ensure = $tls ? {
        true  => 'present',
        false => 'absent',
    }
    # Firewall for Kafka broker on $tls_port
    ferm::service { 'kafka-broker-tls':
        proto   => 'tcp',
        port    => $tls_port,
        notrack => true,
        srange  => '($PRODUCTION_NETWORKS $FRACK_NETWORKS)',
        ensure  => $ferm_tls_ensure,
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
