# == Class profile::kafka::broker
# Sets up a Kafka broker instance belonging to the $kafka_cluster_name
# cluster.  $kafka_cluster_name must have an entry in the hiera 'kafka_clusters'
# variable, and $::fqdn must be listed as a broker there.
#
# == Parameters
# [*kafka_cluster_name*]
#   Kafka cluster name.  This should be the non DC/project suffixed cluster name,
#   e.g. main, aggregate, simple, etc.  The kafka_cluster_name puppet parser
#   function will determine the proper full cluster name based on $::site
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
#   TODO: this does not yet work.
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
#   manages these directories but not anything above them.  Unless the prefix
#   is /srv/kafka, then this profile tries to be nice.  Otherwise,
#   you must ensure that any parent directories exist outside of this class.
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
# [*message_max_bytes*]
#   The largest record batch size allowed by Kafka.
#   If this is increased and there are consumers older
#   than 0.10.2, the consumers' fetch size must also be increased
#   so that the they can fetch record batches this large.
#
# [*monitoring_enabled*]
#   Enable jmxtrans to export metrics to graphite and set up alerts
#   based on its metrics.
#
# [*prometheus_monitoring_enabled*]
#   Enable the Prometheus jmx exporter.
#
class profile::kafka::broker(
    $kafka_cluster_name                = hiera('profile::kafka::broker::kafka_cluster_name'),
    $statsd                            = hiera('statsd'),

    $plaintext                         = hiera('profile::kafka::broker::plaintext'),
    # $tls_secrets_path                = hiera('profile::kafka::broker::tls_secrets_path'),
    # $tls_key_password                = hiera('profile::kafka::broker::tls_key_password'),

    $log_dirs                          = hiera('profile::kafka::broker::log_dirs'),
    $auto_leader_rebalance_enable      = hiera('profile::kafka::broker::auto_leader_rebalance_enable'),
    $log_retention_hours               = hiera('profile::kafka::broker::log_retention_hours'),
    $num_recovery_threads_per_data_dir = hiera('profile::kafka::broker::num_recovery_threads_per_data_dir'),
    $num_io_threads                    = hiera('profile::kafka::broker::num_io_threads'),
    $num_replica_fetchers              = hiera('profile::kafka::broker::num_replica_fetchers'),
    $nofiles_ulimit                    = hiera('profile::kafka::broker::nofiles_ulimit'),
    $replica_maxlag_warning            = hiera('profile::kafka::broker::replica_maxlag_warning'),
    $replica_maxlag_critical           = hiera('profile::kafka::broker::replica_maxlag_critical'),
    # This is set via top level hiera variable so it can be synchronized between roles and clients.
    $message_max_bytes                 = hiera('kafka_message_max_bytes'),
    $monitoring_enabled                = hiera('profile::kafka::broker::monitoring_enabled'),
    $prometheus_monitoring_enabled     = hiera('profile::kafka::broker::prometheus_monitoring_enabled'),
) {
    # TODO: WIP
    $tls_secrets_path = undef
    $tls_key_password = undef

    $config         = kafka_config($kafka_cluster_name)
    $cluster_name   = $config['name']
    $zookeeper_url  = $config['zookeeper']['url']
    $brokers_string = $config['brokers']['string']

    require_package('openjdk-8-jdk')

    # WMF's librdkafka is overriding that in Debian stretch. Require the Stretch version.
    # https://packages.debian.org/stretch/librdkafka1
    if !defined(Package['librdkafka1']) and os_version('debian == stretch') {
        package { 'librdkafka1':
            ensure => '0.9.3-1',
            before => Package['kafkacat'],
        }
    }
    # kafkacat is handy!
    if !defined(Package['kafkacat']) {
        # not using require_package to allow dependency on librdkafka1 in stretch
        package { 'kafkacat': }
    }

    $plaintext_port     = 9092
    $plaintext_listener = "PLAINTEXT://:${plaintext_port}"
    $tls_port           = 9093
    $tls_listener       = "SSL://:${tls_port}"

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

    # TODO:
    #   WIP https://gerrit.wikimedia.org/r/#/c/359960/
    #       https://gerrit.wikimedia.org/r/#/c/355796/
    if $tls_secrets_path {
        # Distribute the Java keystores for this broker's certificate.
        # These need to have been generated with ca-manager and
        # checked into the Puppet private repo in
        # modules/secret/secrets/$tls_secrets_path/$fqdn/.
        # TODO
        # ::ca::certs { "${tls_secrets_path}/${::fqdn}":
        #     destination => '/etc/kafka/tls',
        #     owner       => 'kafka',
        # }

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

    # Be nice, and manage /srv/kafka if it is the prefix for kafka data directories.
    # This is the common case.
    if '/srv/kafka' in $log_dirs[0] and !defined(File['/srv/kafka']) {
        file { '/srv/kafka':
            ensure => 'directory',
            mode   => '0755',
        }
    }

    class { '::confluent::kafka::client':
        # TODO: These should be removed once they are
        # the default in ::confluent::kafka module
        scala_version => '2.11',
        kafka_version => '0.11.0.0-1',
        java_home     => '/usr/lib/jvm/java-8-openjdk-amd64',
    }

    if $prometheus_monitoring_enabled {
        # Allow automatic generation of config on the
        # Prometheus master
        prometheus::jmx_exporter_instance { $::hostname:
            address => $::ipaddress,
            port    => 7800,
        }

        require_package('prometheus-jmx-exporter')

        $jmx_exporter_config_file = '/etc/kafka/broker_prometheus_jmx_exporter.yaml'
        $java_opts = "-javaagent:/usr/share/java/prometheus/jmx_prometheus_javaagent.jar=${::ipaddress}:7800:${jmx_exporter_config_file}"

        # Create the Prometheus JMX Exporter configuration
        file { $jmx_exporter_config_file:
            ensure  => present,
            content => template('profile/kafka/broker_prometheus_jmx_exporter.yaml.erb'),
            owner   => 'kafka',
            group   => 'kafka',
            mode    => '0400',
            require => Class['::confluent::kafka::broker'],
        }
    } else {
        $java_opts = undef
    }

    class { '::confluent::kafka::broker':
        log_dirs                         => $log_dirs,
        brokers                          => $config['brokers']['hash'],
        zookeeper_connect                => $config['zookeeper']['url'],
        nofiles_ulimit                   => $nofiles_ulimit,
        default_replication_factor       => min(3, $config['brokers']['size']),
        offsets_topic_replication_factor => min(3,  $config['brokers']['size']),
        delete_topic_enable              => true,
        # TODO: This can be removed once it is a default
        # in ::confluent::kafka module
        inter_broker_protocol_version    => '0.11.0',
        # Use Kafka/LinkedIn recommended settings with G1 garbage collector.
        # https://kafka.apache.org/documentation/#java
        # Note that MetaspaceSize is a Java 8 setting.
        jvm_performance_opts             => '-server -XX:MetaspaceSize=96m -XX:+UseG1GC -XX:MaxGCPauseMillis=20 -XX:InitiatingHeapOccupancyPercent=35 -XX:G1HeapRegionSize=16M -XX:MinMetaspaceFreeRatio=50 -XX:MaxMetaspaceFreeRatio=80',
        java_opts                        => $java_opts,
        listeners                        => $listeners,

        security_inter_broker_protocol   => $security_inter_broker_protocol,
        ssl_keystore_location            => $ssl_keystore_location,
        ssl_keystore_password            => $ssl_keystore_password,
        ssl_key_password                 => $ssl_key_password,
        ssl_truststore_location          => $ssl_truststore_location,
        ssl_truststore_password          => $ssl_truststore_password,
        ssl_client_auth                  => $ssl_client_auth,

        auto_leader_rebalance_enable     => $auto_leader_rebalance_enable,
        num_replica_fetchers             => $num_replica_fetchers,
        message_max_bytes                => $message_max_bytes,
    }

    if $monitoring_enabled {
        class { '::confluent::kafka::broker::jmxtrans':
            # Cluster metrics prefix for graphite, etc.
            group_prefix => "kafka.cluster.${cluster_name}.",
            statsd       => $statsd,
        }

        class { '::confluent::kafka::broker::alerts':
            replica_maxlag_warning  => $replica_maxlag_warning,
            replica_maxlag_critical => $replica_maxlag_critical,
        }
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
