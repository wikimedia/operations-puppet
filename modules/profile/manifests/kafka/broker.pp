# == Class profile::kafka::broker
# Sets up a Kafka broker instance belonging to the $kafka_cluster_name
# cluster.  $kafka_cluster_name must have an entry in the hiera 'kafka_clusters'
# variable, and $::fqdn must be listed as a broker there.
#
# == SSL Configuration
#
# To configure SSL for Kafka brokers, you need the following files distributable by our Puppet
# secret() function.
#
# - A keystore.jks file   - Contains the key and certificate for this broker
# - A truststore.jks file - Contains the CA certificate that signed the broker's certificate
#
# It is expected that the CA certificate in the truststore will also be used to sign
# all Kafka client certificates.
#
# Once these are in the Puppet private repository's secret module, set
# $ssl_enabled to true, $ssl_keystore_source and $ssl_truststore_source to their
# relative path in the secrets directory, and also set $ssl_password to the password
# used when genrating key, keystore, and truststore.
#
# The default values of $ssl_keystore_secrets_path and $ssl_truststore_secrets_path expect
# that you used cergen to generate and commit files in the private puppet
# repository in the secret module at modules/secret/secrets/certificates.  If you did, then you
# need only set $ssl_enabled and $ssl_password.
#
# See https://wikitech.wikimedia.org/wiki/Cergen for more details.
#
# == Parameters
#
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
#   Hiera: profile::kafka::broker::plaintext.  Default true.
#
# [*ssl_enabled*]
#   If true, an SSL listener will be configured.  Default: false
#
# [*ssl_keystore_secrets_path*]
#   The relative puppet path to the keystore.jks file in the private puppet repo
#   secret module secrets directory.
#   Default: certificates/kafka_broker_${::hostname}/kafka_broker_${::hostname}.keystore.jks
#   This default assumes that you have a keystore.jks file created with cergen in the puppet
#   private repository in certificates/kafka_broker_${::hostname}/
#
# [*ssl_truststore_secrets_path*]
#   If given, Kafka SSL will be configured with a truststore, which means that
#   client certificates must be signed by the CA cert inside the truststore.
#   Default: certificates/kafka_broker_${::hostname}/puppet_ca.truststore.jks
#   This default assumes that you have a truststore.jks file created with cergen in the puppet
#   private repository in certificates/kafka_broker_${::hostname}/
#
# [*ssl_password*]
#   Password for keystores and keys.  You should
#   set this in hiera in the operations puppet private repository.
#   Hiera: profile::kafka::broker::ssl_password  This expects
#   that all keystore, truststores, and keys use the same password.
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
#   Default: 8192
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
#   This will also increase the verbosity of authorization logs for a better
#   user accounting.  Default: false
#
# [*monitoring_enabled*]
#   Enable monitoring and alerts for this broker.  Default: false
#
class profile::kafka::broker(
    $kafka_cluster_name                = hiera('profile::kafka::broker::kafka_cluster_name'),
    $statsd                            = hiera('statsd'),

    $plaintext                         = hiera('profile::kafka::broker::plaintext', true),

    $ssl_enabled                       = hiera('profile::kafka::broker::ssl_enabled', false),
    $ssl_keystore_secrets_path         = hiera('profile::kafka::broker::ssl_keystore_secrets_path', "certificates/kafka_broker_${::hostname}/kafka_broker_${::hostname}.keystore.jks"),
    $ssl_truststore_secrets_path       = hiera('profile::kafka::broker::ssl_truststore_secrets_path', "certificates/kafka_broker_${::hostname}/truststore.jks"),
    $ssl_password                      = hiera('profile::kafka::broker::ssl_password', undef),

    $log_dirs                          = hiera('profile::kafka::broker::log_dirs', ['/srv/kafka']),
    $auto_leader_rebalance_enable      = hiera('profile::kafka::broker::auto_leader_rebalance_enable', true),
    $log_retention_hours               = hiera('profile::kafka::broker::log_retention_hours', 168),
    $num_recovery_threads_per_data_dir = hiera('profile::kafka::broker::num_recovery_threads_per_data_dir', undef),
    $num_io_threads                    = hiera('profile::kafka::broker::num_io_threads', 1),
    $num_replica_fetchers              = hiera('profile::kafka::broker::num_replica_fetchers', undef),
    $nofiles_ulimit                    = hiera('profile::kafka::broker::nofiles_ulimit', 8192),
    # This is set via top level hiera variable so it can be synchronized between roles and clients.
    $message_max_bytes                 = hiera('kafka_message_max_bytes', 1048576),
    $auth_acls_enabled                 = hiera('profile::kafka::broker::auth_acls_enabled', false),
    $monitoring_enabled                = hiera('profile::kafka::broker::monitoring_enabled', false),
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
    $ssl_port           = 9093
    $ssl_listener       = "SSL://:${ssl_port}"

    # Conditionally set $listeners and $ssl_client_auth
    # based on values of $tls and $plaintext.
    if $ssl_enabled and $plaintext {
        $listeners = [$plaintext_listener, $ssl_listener]
        $ssl_client_auth       = 'requested'
    }
    elsif $plaintext {
        $listeners             = [$plaintext_listener]
        $ssl_client_auth       = 'none'
    }
    elsif $ssl_enabled {
        $listeners             = [$ssl_listener]
        $ssl_client_auth       = 'required'
    }
    else {
        fatal('Must set at least one of $plaintext or $ssl_enabled to true.')
    }

    if $ssl_enabled {
        # Distribute Java keystore and truststore for this broker.
        $certificates_path = '/etc/kafka/certificates'
        $ssl_keystore_location          = "/etc/kafka/certificates/kafka_broker_${::hostname}.keystore.jks"

        file { $certificates_path:
            ensure => 'directory',
            owner  => 'kafka',
            group  => 'kafka',
            mode   => '0555',
        }
        file { $ssl_keystore_location:
            content => secret($ssl_keystore_secrets_path),
            owner   => 'kafka',
            group   => 'kafka',
            mode    => '0440',
            # Install certificates after confluent-kafka package has been
            # installed and /etc/kafka already exists...
            require => Class['::confluent::kafka::common'],
            # But before Kafka broker is started.
            before  => Class['::confluent::kafka::broker'],
        }

        $security_inter_broker_protocol = 'SSL'
        $ssl_keystore_password          = $ssl_password
        $ssl_key_password               = $ssl_password

        if $ssl_truststore_secrets_path {
            $ssl_truststore_location = "${certificates_path}/truststore.jks"
            $ssl_truststore_password = $ssl_password

            file { $ssl_truststore_location:
                content => secret($ssl_truststore_secrets_path),
                owner   => 'kafka',
                group   => 'kafka',
                mode    => '0444',
                require => Class['::confluent::kafka::common'],
                before  => Class['::confluent::kafka::broker'],
            }
        }
        else {
            $ssl_truststore_location = undef
            $ssl_truststore_password = undef
        }
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

    class { '::confluent::kafka::common':
        # TODO: These should be removed once they are
        # the default in ::confluent::kafka module
        scala_version => '2.11',
        kafka_version => '0.11.0.1-1',
        java_home     => '/usr/lib/jvm/java-8-openjdk-amd64',
    }

    # If monitoring is enabled, then include the monitoring profile and set $java_opts
    # for exposing the Prometheus JMX Exporter in the Kafka Broker process.
    if $monitoring_enabled {
        include ::profile::kafka::broker::monitoring
        $java_opts = $::profile::kafka::broker::monitoring::java_opts
    }
    else {
        $java_opts = undef
    }

    if $auth_acls_enabled {
        $authorizer_class_name = 'kafka.security.auth.SimpleAclAuthorizer'
    }
    else {
        $authorizer_class_name = undef
    }

    class { '::confluent::kafka::broker':
        log_dirs                         => $log_dirs,
        brokers                          => $config['brokers']['hash'],
        zookeeper_connect                => $config['zookeeper']['url'],
        nofiles_ulimit                   => $nofiles_ulimit,
        default_replication_factor       => min(3, $config['brokers']['size']),
        offsets_topic_replication_factor => min(3,  $config['brokers']['size']),
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
        authorizer_class_name            => $authorizer_class_name,
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
