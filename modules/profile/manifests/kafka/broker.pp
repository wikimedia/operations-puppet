# == Class profile::kafka::broker
# Sets up a Kafka broker instance belonging to the $kafka_cluster_name
# cluster.  $kafka_cluster_name must have an entry in the hiera 'kafka_clusters'
# variable, and $::fqdn must be listed as a broker there.
#
# If both $plaintext and $auth_acls_enabled, User:ANONYMOUS will be auto-granted
# cluster describe and topic creation permissions in Kafka ACLs.
#
# == SSL Configuration
#
# To configure SSL for Kafka brokers, you need the following files distributable by our Puppet
# secret() function.
#
# - A keystore.jks file   - Contains the key and certificate for this kafka cluster's brokers.
# - A truststore.jks file - Contains the CA certificate that signed the cluster certificate
#
# It is expected that the CA certificate in the truststore will also be used to sign
# all Kafka client certificates.  These should be checked into the Puppet private repository's
# secret module at
#
#   - secrets/certificates/kafka_${kafka_cluster_name_full}_broker/kafka_${kafka_cluster_name_full}_broker.keystore.jks
#   - secrets/certificates/kafka_${kafka_cluster_name_full}_broker/truststore.jks
#
# Where ${kafka_cluster_name_full} is the fully qualified Kafka cluster name that matches
# entries in the $kafka_clusters hash.  E.g. jumbo-eqiad, main-codfw, etc.
#
# If both $ssl_enabled and $auth_acls_enabled, this class will configure super.users
# with the cluster certificate principal. It is expected that the certificate is
# subjectless, i.e. it's DN can be specified simply as CN=kafka_${kafka_cluster_name_full}_broker.
# This will be used as the Kafka cluster broker principal. super.users will be set to
# User:CN=kafka_${kafka_cluster_name_full}_broker to allow for cluster operations over SSL.
#
# This layout is built to work with certificates generated using cergen like
#    cergen --base-path /srv/private/modules/secret/secrets/certificates ...
#
# Once these are in the Puppet private repository's secret module, set
# $ssl_enabled to true and  $ssl_password to the password
# used when genrating the key, keystore, and truststore.
#
# See https://wikitech.wikimedia.org/wiki/Cergen for more details.
#
# Note that this class configures java.security to set jdk.certpath.disabledAlgorithms
# to restrict the types of sigalgs used for authentication certificates.
#
# == Parameters
#
# [*kafka_cluster_name*]
#   Kafka cluster name.  This should be the non DC/project suffixed cluster name,
#   e.g. main, aggregate, simple, etc.  The kafka_cluster_name() puppet parser
#   function will determine the proper full cluster name based on $::site
#   and/or $::labsproject.  Hiera: kafka_cluster_name
#
# [*statsd*]
#   Statsd URI to use for metrics.  Hiera: statsd
#
# [*plaintext*]
#   Boolean whether to use a plaintext listener on port 9092.
#   Hiera: profile::kafka::broker::plaintext.  Default true.
#
# [*ssl_enabled*]
#   If true, an SSL listener will be configured.  Default: false
#
# [*ssl_password*]
#   Password for keystores and keys.  You should
#   set this in hiera in the operations puppet private repository.
#   Hiera: profile::kafka::broker::ssl_password  This expects
#   that all keystore, truststores, and keys use the same password.
#   Default: undef
#
# [*inter_broker_ssl_enabled*]
#   Vary security.inter.broker.protocol based on this and $ssl_enabled.
#   If this is undef (default) and $ssl_enabled, we'll pick SSL.
#   Else if this is false, we'll use PLAINTEXT, or true, SSL.
#   This only is used if ssl_enabled is true.
#   Default: undef
#
# [*log_dirs*]
#   Array of Kafka log data directories.  The confluent::kafka::broker class
#   manages these directories but not anything above them.  Unless the prefix
#   is /srv/kafka, then this profile tries to be nice.  Otherwise,
#   you must ensure that any parent directories exist outside of this class.
#   Hiera: profile::kafka::broker::log_dirs  Default: ['/srv/kafka']
#
# [*auto_leader_rebalance_enable*]
#   Hiera: profile::kafka::broker::auto_leader_rebalance_enable
#   Default: true
#
# [*log_retention_hours*]
#   Hiera: profile::kafka::broker::log_retention_hours  Default: 168 (1 week)
#
# [*log_retention_bytes*]
#   Hiera: profile::kafka::broker::log_retention_bytes Default: undef
#
# [*log_segement_bytes*]
#   Hiera: profile::kafka::broker::log.segment.bytes Default: undef (1GiB)
#
# [*num_recovery_threads_per_data_dir*]
#   Hiera: profile::kafka::broker::num_recovery_threads_per_data_dir  Default undef
#
# [*num_io_threads*]
#   Hiera: profile::kafka::broker::num_replica_fetchers  Default 1
#
# [*num_replica_fetchers*]
#   Hiera: profile::kafka::broker::num_replica_fetchers  Default undef
#
# [*nofiles_ulimit*]
#   Hiera: profile::kafka::broker::nofiles_ulimit
#   Default: 128000
#
# [*inter_broker_protocol_version*]
#   Default: undef
#
# [*group_initial_rebalance_delay*]
#   The time, in milliseconds, that the `GroupCoordinator` will delay the initial consumer rebalance.
#   Default: undef
#
# [*log_message_format_version*]
#   Default: undef
#
# [*message_max_bytes*]
#   The largest record batch size allowed by Kafka.
#   If this is increased and there are consumers older
#   than 0.10.2, the consumers' fetch size must also be increased
#   so that the they can fetch record batches this large.
#   Default: 1048576
#
# [*auth_acls_enabled*]
#   Enables the kafka.security.auth.SimpleAclAuthorizer bundled with Kafka.
#   Default: false
#
# [*scala_version*]
#   Used to install proper confluent kafka package.  Default: 2.11
#
# [*kafka_version*]
#   Used to install proper confluent kafka package.  Default: undef
#
# [*monitoring_enabled*]
#   Enable monitoring and alerts for this broker.  Default: false
#
# [*max_heap_size*]
#   Value for -Xms and -Xmx to pass to the JVM. Example: '8g'
#   Default: undef
#
# [*num_partitions*]
#   The default number of partitions per topic.
#   Default: 1
#
class profile::kafka::broker(
    $kafka_cluster_name                = hiera('profile::kafka::broker::kafka_cluster_name'),
    $statsd                            = hiera('statsd'),

    $plaintext                         = hiera('profile::kafka::broker::plaintext', true),

    $ssl_enabled                       = hiera('profile::kafka::broker::ssl_enabled', false),
    $ssl_password                      = hiera('profile::kafka::broker::ssl_password', undef),
    $inter_broker_ssl_enabled          = hiera('profile::kafka::broker::inter_broker_ssl_enabled', undef),

    $log_dirs                          = hiera('profile::kafka::broker::log_dirs', ['/srv/kafka/data']),
    $auto_leader_rebalance_enable      = hiera('profile::kafka::broker::auto_leader_rebalance_enable', true),
    $log_retention_hours               = hiera('profile::kafka::broker::log_retention_hours', 168),
    $log_retention_bytes               = hiera('profile::kafka::broker::log_retention_bytes', undef),
    $log_segment_bytes                 = hiera('profile::kafka::broker::log_segment_bytes', undef),
    $num_recovery_threads_per_data_dir = hiera('profile::kafka::broker::num_recovery_threads_per_data_dir', undef),
    $num_io_threads                    = hiera('profile::kafka::broker::num_io_threads', 1),
    $num_replica_fetchers              = hiera('profile::kafka::broker::num_replica_fetchers', undef),
    $nofiles_ulimit                    = hiera('profile::kafka::broker::nofiles_ulimit', 128000),
    $inter_broker_protocol_version     = hiera('profile::kafka::broker::inter_broker_protocol_version', undef),
    $group_initial_rebalance_delay     = hiera('profile::kafka::broker::group_initial_rebalance_delay', undef),
    $log_message_format_version        = hiera('profile::kafka::broker::log_message_format_version', undef),

    # This is set via top level hiera variable so it can be synchronized between roles and clients.
    $message_max_bytes                 = hiera('kafka_message_max_bytes', 1048576),
    $auth_acls_enabled                 = hiera('profile::kafka::broker::auth_acls_enabled', false),
    $monitoring_enabled                = hiera('profile::kafka::broker::monitoring_enabled', false),

    $scala_version                     = hiera('profile::kafka::broker::scala_version', '2.11'),
    $kafka_version                     = hiera('profile::kafka::broker::kafka_version', undef),

    $max_heap_size                     = hiera('profile::kafka::broker::max_heap_size', undef),
    $num_partitions                    = hiera('profile::kafka::broker::num_partitions', 1),
) {
    $config         = kafka_config($kafka_cluster_name)
    $cluster_name   = $config['name']
    $zookeeper_url  = $config['zookeeper']['url']
    $brokers_string = $config['brokers']['string']

    require_package('openjdk-8-jdk')
    $java_home = '/usr/lib/jvm/java-8-openjdk-amd64'
    # Use Java 8 GC features
    # Use Kafka/LinkedIn recommended settings with G1 garbage collector.
    # https://kafka.apache.org/documentation/#java
    # Note that MetaspaceSize is a Java 8 setting.
    $jvm_performance_opts = '-server -XX:MetaspaceSize=96m -XX:+UseG1GC -XX:MaxGCPauseMillis=20 -XX:InitiatingHeapOccupancyPercent=35 -XX:G1HeapRegionSize=16M -XX:MinMetaspaceFreeRatio=50 -XX:MaxMetaspaceFreeRatio=80'

    # kafkacat is handy!
    require_package('kafkacat')

    $plaintext_port     = 9092
    $plaintext_listener = "PLAINTEXT://:${plaintext_port}"
    $ssl_port           = 9093
    $ssl_listener       = "SSL://:${ssl_port}"

    # Conditionally set $listeners
    # based on values of $ssl_enabled and $plaintext.
    if $ssl_enabled and $plaintext {
        $listeners = [$plaintext_listener, $ssl_listener]
    }
    elsif $plaintext {
        $listeners = [$plaintext_listener]
    }
    elsif $ssl_enabled {
        $listeners = [$ssl_listener]
    }
    else {
        fail('Must set at least one of $plaintext or $ssl_enabled to true.')
    }

    if $ssl_enabled {
        # If $inter_broker_ssl_enabled has not been overridden, then use SSL.
        # Else if it has, use SSL or PLAINTEXT.
        $security_inter_broker_protocol = $inter_broker_ssl_enabled ? {
            undef => 'SSL',
            true  => 'SSL',
            false => 'PLAINTEXT',
        }

        # Distribute Java keystore and truststore for this broker.
        $ssl_location                = '/etc/kafka/ssl'

        $ssl_keystore_secrets_path   = "certificates/kafka_${cluster_name}_broker/kafka_${cluster_name}_broker.keystore.jks"
        $ssl_keystore_location       = "${ssl_location}/kafka_${cluster_name}_broker.keystore.jks"

        $ssl_truststore_secrets_path = "certificates/kafka_${cluster_name}_broker/truststore.jks"
        $ssl_truststore_location     = "${ssl_location}/truststore.jks"

        $ssl_enabled_protocols       = 'TLSv1.2'
        $ssl_cipher_suites           = 'TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384'

        # https://phabricator.wikimedia.org/T182993#4208208
        $ssl_java_opts               = '-Djdk.tls.namedGroups=secp256r1 -XX:+UseAES -XX:+UseAESIntrinsics'

        $super_users                 = ["User:CN=kafka_${cluster_name}_broker"]

        if !defined(File[$ssl_location]) {
            file { $ssl_location:
                ensure  => 'directory',
                owner   => 'kafka',
                group   => 'kafka',
                mode    => '0555',
                # Install certificates after confluent-kafka package has been
                # installed and /etc/kafka already exists.
                require => Class['::confluent::kafka::common'],
            }
        }
        file { $ssl_keystore_location:
            content => secret($ssl_keystore_secrets_path),
            owner   => 'kafka',
            group   => 'kafka',
            mode    => '0440',
            before  => Class['::confluent::kafka::broker'],
        }

        if !defined(File[$ssl_truststore_location]) {
            file { $ssl_truststore_location:
                content => secret($ssl_truststore_secrets_path),
                owner   => 'kafka',
                group   => 'kafka',
                mode    => '0444',
                before  => Class['::confluent::kafka::broker'],
            }
        }

        # Use a custom java.security on this host, so that we can restrict the allowed
        # certiifcate sigalgs.  See: https://phabricator.wikimedia.org/T182993
        file { '/etc/java-8-openjdk/security/java.security':
            source => 'puppet:///modules/profile/kafka/java.security',
            before => Class['::confluent::kafka::broker'],
        }
    }
    else {
        $security_inter_broker_protocol = undef
        $ssl_keystore_location          = undef
        $ssl_truststore_location        = undef
        $ssl_enabled_protocols          = undef
        $ssl_cipher_suites              = undef
        $ssl_java_opts                  = undef
        $super_users                    = undef
    }

    # Enable ACL based authorization.
    if $auth_acls_enabled {
        $authorizer_class_name = 'kafka.security.auth.SimpleAclAuthorizer'

        # Conditionally set $ssl_client_auth
        # based on values of $auth_acls_enabled, $ssl_enabled and $plaintext.
        if $ssl_enabled and $plaintext {
            $ssl_client_auth   = 'requested'
        }
        elsif $plaintext {
            $ssl_client_auth   = 'none'
        }
        elsif $ssl_enabled {
            $ssl_client_auth   = 'required'
        }
    }
    else {
        $authorizer_class_name = undef
        $ssl_client_auth       = undef
    }

    # Be nice, and manage /srv/kafka if it is the prefix for kafka data directories.
    # This is the common case.
    if '/srv/kafka' in $log_dirs[0] and !defined(File['/srv/kafka']) {
        file { '/srv/kafka':
            ensure => 'directory',
            mode   => '0755',
        }
    }

    class { '::confluent::kafka::common':
        scala_version => $scala_version,
        kafka_version => $kafka_version,
        java_home     => $java_home,
    }

    # If monitoring is enabled, then include the monitoring profile and set $java_opts
    # for exposing the Prometheus JMX Exporter in the Kafka Broker process.
    if $monitoring_enabled {
        include ::profile::kafka::broker::monitoring
        $monitoring_java_opts = $::profile::kafka::broker::monitoring::java_opts
    }
    else {
        $monitoring_java_opts = undef
    }

    $java_opts = "${monitoring_java_opts} ${ssl_java_opts}"

    if $max_heap_size {
        $heap_opts = "-Xms${max_heap_size} -Xmx${max_heap_size}"
    } else {
        $heap_opts = undef
    }

    class { '::confluent::kafka::broker':
        log_dirs                         => $log_dirs,
        brokers                          => $config['brokers']['hash'],
        zookeeper_connect                => $config['zookeeper']['url'],
        nofiles_ulimit                   => $nofiles_ulimit,
        default_replication_factor       => min(3, $config['brokers']['size']),
        offsets_topic_replication_factor => min(3, $config['brokers']['size']),
        inter_broker_protocol_version    => $inter_broker_protocol_version,
        group_initial_rebalance_delay    => $group_initial_rebalance_delay,
        log_message_format_version       => $log_message_format_version,

        jvm_performance_opts             => $jvm_performance_opts,
        java_opts                        => $java_opts,
        heap_opts                        => $heap_opts,
        listeners                        => $listeners,

        security_inter_broker_protocol   => $security_inter_broker_protocol,
        ssl_keystore_location            => $ssl_keystore_location,
        ssl_keystore_password            => $ssl_password,
        ssl_key_password                 => $ssl_password,
        ssl_truststore_location          => $ssl_truststore_location,
        ssl_truststore_password          => $ssl_password,
        ssl_client_auth                  => $ssl_client_auth,
        ssl_enabled_protocols            => $ssl_enabled_protocols,
        ssl_cipher_suites                => $ssl_cipher_suites,

        log_retention_hours              => $log_retention_hours,
        log_retention_bytes              => $log_retention_bytes,
        log_segment_bytes                => $log_segment_bytes,
        auto_leader_rebalance_enable     => $auto_leader_rebalance_enable,
        num_replica_fetchers             => $num_replica_fetchers,
        message_max_bytes                => $message_max_bytes,
        authorizer_class_name            => $authorizer_class_name,
        super_users                      => $super_users,
        num_partitions                   => $num_partitions,
    }

    $ferm_srange = $::realm ? {
        'production' => '($PRODUCTION_NETWORKS $FRACK_NETWORKS)',
        'labs'       => '($LABS_NETWORKS)',
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
        srange  => $ferm_srange,
    }

    $ferm_ssl_ensure = $ssl_enabled ? {
        false   => 'absent',
        undef   => 'absent',
        default => 'present'
    }
    # Firewall for Kafka broker on $ssl_port
    ferm::service { 'kafka-broker-ssl':
        ensure  => $ferm_ssl_ensure,
        proto   => 'tcp',
        port    => $ssl_port,
        notrack => true,
        srange  => $ferm_srange,
    }

    # In case of mediawiki spikes we've been seeing up to 300k connections,
    # so raise the connection table size on Kafka brokers (default is 256k)
    sysctl::parameters { 'kafka_conntrack':
        values   => {
            'net.netfilter.nf_conntrack_max' => 524288,
        },
        priority => 75,
    }
}
