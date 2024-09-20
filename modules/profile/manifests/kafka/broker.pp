# SPDX-License-Identifier: Apache-2.0
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
# To configure SSL for Kafka brokers, you have two options:
# 1) PKI TLS certificates (default and preferred way)
# In this case you just need to populate the $ssl_password field in the private
# repository, and make sure that the role's config includes
# "profile::base::certificates::include_bundle_jks" set to true to have
# the right truststore CA bundle deployed on all nodes.
# 2) Puppet TLS certificates (discouraged, mainly kept for backward compatibility)
# You need the following files distributable by our Puppet secret() function:
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
# to restrict the types of sigalgs used for authentication certificates via
# the profile::java hardened_tls parameter.
#
# == Parameters
#
# [*kafka_cluster_name*]
#   Kafka cluster name.  This should be the non DC/project suffixed cluster name,
#   e.g. main, aggregate, simple, etc.  The kafka_cluster_name() puppet parser
#   function will determine the proper full cluster name based on $::site
#   and/or $::wmcs_project.  Hiera: kafka_cluster_name
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
# [*max_incremental_fetch_session_cache_slots*]
#   The maximum number of incremental fetch sessions that we will maintain.
#   Scale this if you consistently have more than the default (1000) number
#   of client connections
#   (consistently == within the min.incremental.fetch.session.eviction.ms default of 120 seconds).
#   Default: undef (1000).
#
# [*message_max_bytes*]
#   The largest record batch size allowed by Kafka.
#   If this is increased and there are consumers older
#   than 0.10.2, the consumers' fetch size must also be increased
#   so that they can fetch record batches this large.
#   Default: 1048576
#
# [*auth_acls_enabled*]
#   Enables the kafka.security.auth.SimpleAclAuthorizer bundled with Kafka.
#   Default: false
#
# [*scala_version*]
#   Used to install proper confluent kafka package.  Default: 2.11
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
    String $kafka_cluster_name                                   = lookup('profile::kafka::broker::kafka_cluster_name'),
    String $statsd                                               = lookup('statsd'),

    Boolean $plaintext                                           = lookup('profile::kafka::broker::plaintext', {'default_value' => true}),

    Boolean $ssl_enabled                                         = lookup('profile::kafka::broker::ssl_enabled', {'default_value' => false}),
    Optional[String] $ssl_password                               = lookup('profile::kafka::broker::ssl_password', {'default_value' => undef}),
    Optional[Boolean] $inter_broker_ssl_enabled                  = lookup('profile::kafka::broker::inter_broker_ssl_enabled', {'default_value' => undef}),
    Array[Stdlib::Unixpath] $log_dirs                            = lookup('profile::kafka::broker::log_dirs', {'default_value' => ['/srv/kafka/data']}),
    Boolean $auto_leader_rebalance_enable                        = lookup('profile::kafka::broker::auto_leader_rebalance_enable', {'default_value' => true}),
    Integer $log_retention_hours                                 = lookup('profile::kafka::broker::log_retention_hours', {'default_value' => 168}),
    Optional[Integer] $log_retention_bytes                       = lookup('profile::kafka::broker::log_retention_bytes', {'default_value' => undef}),
    Optional[Integer] $log_segment_bytes                         = lookup('profile::kafka::broker::log_segment_bytes', {'default_value' => undef}),
    Optional[Integer] $num_recovery_threads_per_data_dir         = lookup('profile::kafka::broker::num_recovery_threads_per_data_dir', {'default_value' => undef}),
    Integer $num_io_threads                                      = lookup('profile::kafka::broker::num_io_threads', {'default_value' => 1}),
    Optional[Integer] $num_replica_fetchers                      = lookup('profile::kafka::broker::num_replica_fetchers', {'default_value' => undef}),
    Integer $nofiles_ulimit                                      = lookup('profile::kafka::broker::nofiles_ulimit', {'default_value' => 128000}),
    Optional[String] $inter_broker_protocol_version              = lookup('profile::kafka::broker::inter_broker_protocol_version', {'default_value' => undef}),
    Optional[Integer] $group_initial_rebalance_delay             = lookup('profile::kafka::broker::group_initial_rebalance_delay', {'default_value' => undef}),
    Optional[String] $log_message_format_version                 = lookup('profile::kafka::broker::log_message_format_version', {'default_value' => undef}),
    Optional[Integer] $max_incremental_fetch_session_cache_slots = lookup('profile::kafka::broker::max_incremental_fetch_session_cache_slots', {'default_value' => undef}),

    # This is set via top level hiera variable so it can be synchronized between roles and clients.
    Integer $message_max_bytes                                   = lookup('kafka_message_max_bytes', {'default_value' => 1048576}),
    Boolean $auth_acls_enabled                                   = lookup('profile::kafka::broker::auth_acls_enabled', {'default_value' => false}),
    Boolean $monitoring_enabled                                  = lookup('profile::kafka::broker::monitoring_enabled', {'default_value' => false}),

    String $scala_version                                        = lookup('profile::kafka::broker::scala_version', {'default_value' => '2.11'}),

    Optional[String] $max_heap_size                              = lookup('profile::kafka::broker::max_heap_size', {'default_value' => undef}),
    Integer $num_partitions                                      = lookup('profile::kafka::broker::num_partitions', {'default_value' => 1}),
    Optional[Array[String]] $custom_ferm_srange_components       = lookup('profile::kafka::broker::custom_ferm_srange_components', { 'default_value' => undef }),
    Optional[String] $prometheus_cluster_name                    = lookup('cluster'),
) {
    include profile::kafka::common

    $config         = kafka_config($kafka_cluster_name)
    $cluster_name   = $config['name']
    $zookeeper_url  = $config['zookeeper']['url']
    $brokers_string = $config['brokers']['string']

    # NOTE: Kafka brokers support openjdk-11 only from 2.1:
    # https://issues.apache.org/jira/browse/KAFKA-7264
    # For now we use java 8.
    class { 'profile::java':
        # If $ssl_enabled, use a custom java.security on this host
        # so that we can restrict the allowed certificate's sigalgs.
        # See: https://phabricator.wikimedia.org/T182993
        hardened_tls => $ssl_enabled,
    }
    $java_home = $::profile::java::default_java_home

    # Use Java 8 GC features
    # Use Kafka/LinkedIn recommended settings with G1 garbage collector.
    # https://kafka.apache.org/documentation/#java
    # Note that MetaspaceSize is a Java 8 setting.
    $jvm_performance_opts = '-server -XX:MetaspaceSize=96m -XX:+UseG1GC -XX:MaxGCPauseMillis=20 -XX:InitiatingHeapOccupancyPercent=35 -XX:G1HeapRegionSize=16M -XX:MinMetaspaceFreeRatio=50 -XX:MaxMetaspaceFreeRatio=80'

    # kafkacat is handy!
    ensure_packages('kafkacat')

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
        $ssl_location = $profile::kafka::common::kafka_ssl_dir
        $ssl_enabled_protocols = 'TLSv1.2'
        $ssl_cipher_suites = 'TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384'
        # https://phabricator.wikimedia.org/T182993#4208208
        $ssl_java_opts = '-Djdk.tls.namedGroups=secp256r1 -XX:+UseAES -XX:+UseAESIntrinsics'

        # Context: T291905
        # We are trying to migrate all Kafka clusters to the new PKI Kafka
        # intermediate CA.
        # To ensure a smooth transition on a given cluster, we need to:
        # 1) make sure that brokers trust both the old 'single' CN and all the new
        # ones (basically all the Kafka broker hostnames).
        # 2) make sure that brokers trust the Puppet CA and the Root PKI CA
        # in their truststores.
        $brokers = $config['brokers']['array']
        $super_users_brokers = $brokers.map |String $hostname| {
            "User:CN=${hostname}"
        }

        $super_users = $super_users_brokers
        $ssl_truststore_location = profile::base::certificates::get_trusted_ca_jks_path()
        $ssl_truststore_password = profile::base::certificates::get_trusted_ca_jks_password()

        # Set kafka broker certificates to renew 1 month before expiration as kafka uses a
        # custom 1 year certificate lifespan.  This aims to provide ample time for manual
        # broker restarts to activate new certificates, and ensure that renewed certs are
        # present on-disk before alerting warns of upcoming expiration T358870
        $ssl_cert = profile::pki::get_cert('kafka', $facts['networking']['fqdn'], {
            'renew_seconds' => 2678400, #1 month
            'outdir'        => $ssl_location,
            'owner'         => 'kafka',
            'profile'       => 'kafka_11',
            'hosts'         => [
                $facts['networking']['hostname'],
                $facts['networking']['fqdn'],
                $facts['networking']['ip'],
                $facts['networking']['ip6'],
                # This is the DNS name generated by the external-services chart for use from within kubernetes, see:
                # - https://wikitech.wikimedia.org/wiki/Kubernetes/Deployment_Charts#Enabling_egress_to_services_external_to_Kubernetes
                # - https://phabricator.wikimedia.org/T374729
                "kafka-${cluster_name}.external-services.svc.cluster.local",
            ],
            notify          => Sslcert::X509_to_pkcs12['kafka_keystore'],
            require         => Class['::confluent::kafka::common'],
        })

        $ssl_keystore_location   = "${ssl_location}/kafka_${cluster_name}_broker.keystore.p12"
        sslcert::x509_to_pkcs12 { 'kafka_keystore' :
            owner       => 'kafka',
            group       => 'kafka',
            public_key  => $ssl_cert['chained'],
            private_key => $ssl_cert['key'],
            certfile    => $ssl_cert['ca'],
            outfile     => $ssl_keystore_location,
            password    => $ssl_password,
            require     => Class['::confluent::kafka::common'],
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
        java_home     => $java_home,
        user_group_id => 916, # Reserved uid/gid in the admin module
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
        log_dirs                                  => $log_dirs,
        brokers                                   => $config['brokers']['hash'],
        zookeeper_connect                         => $config['zookeeper']['url'],
        nofiles_ulimit                            => $nofiles_ulimit,
        default_replication_factor                => min(3, $config['brokers']['size']),
        offsets_topic_replication_factor          => min(3, $config['brokers']['size']),
        inter_broker_protocol_version             => $inter_broker_protocol_version,
        group_initial_rebalance_delay             => $group_initial_rebalance_delay,
        log_message_format_version                => $log_message_format_version,

        jvm_performance_opts                      => $jvm_performance_opts,
        java_opts                                 => $java_opts,
        heap_opts                                 => $heap_opts,
        listeners                                 => $listeners,

        security_inter_broker_protocol            => $security_inter_broker_protocol,
        ssl_keystore_location                     => $ssl_keystore_location,
        ssl_keystore_password                     => $ssl_password,
        ssl_key_password                          => $ssl_password,
        ssl_truststore_location                   => $ssl_truststore_location,
        ssl_truststore_password                   => $ssl_truststore_password,
        ssl_client_auth                           => $ssl_client_auth,
        ssl_enabled_protocols                     => $ssl_enabled_protocols,
        ssl_cipher_suites                         => $ssl_cipher_suites,

        log_retention_hours                       => $log_retention_hours,
        log_retention_bytes                       => $log_retention_bytes,
        log_segment_bytes                         => $log_segment_bytes,
        auto_leader_rebalance_enable              => $auto_leader_rebalance_enable,
        num_replica_fetchers                      => $num_replica_fetchers,
        max_incremental_fetch_session_cache_slots => $max_incremental_fetch_session_cache_slots,
        message_max_bytes                         => $message_max_bytes,
        authorizer_class_name                     => $authorizer_class_name,
        super_users                               => $super_users,
        num_partitions                            => $num_partitions,
        num_io_threads                            => $num_io_threads,
        num_recovery_threads_per_data_dir         => $num_recovery_threads_per_data_dir,
        # Make sure that java is installed and configured before the kafka broker service.
        require                                   => Class['::profile::java'],
    }

    if $custom_ferm_srange_components {
        $ferm_srange_components = join($custom_ferm_srange_components, ' ')
        $ferm_srange = "(${ferm_srange_components})"
    } else {
        $ferm_srange = $::realm ? {
            'production' => '($PRODUCTION_NETWORKS $FRACK_NETWORKS)',
            'labs'       => '($LABS_NETWORKS)',
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

    ensure_packages(['python3-kazoo'])
    file { '/usr/local/bin/kafka-broker-in-sync':
        source => 'puppet:///modules/profile/kafka/kafka-broker-in-sync.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    # Install kafka-kit (https://gitlab.wikimedia.org/repos/sre/kafka-kit) on each broker
    profile::kafka::kafka_kit { $kafka_cluster_name:
        zookeeper_address              => $config['zookeeper']['hosts'][0],
        zookeeper_prefix               => $config['zookeeper']['chroot'],
        zookeeper_metrics_prefix       => "kafka/${cluster_name}/topicmappr",
        kafka_address                  => $brokers_string,
        kafka_cluster_prometheus_label => $prometheus_cluster_name,
        prometheus_url                 => "http://prometheus.svc.${::site}.wmnet/ops",
        brokers                        => $config['brokers']['hash'],
    }
}
