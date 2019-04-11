# == Class confluent::kafka::broker
#
# Sets up a Kafka Broker and ensures that it is running.
#
# == Parameters:
#
# [*enabled*]
#  Boolean.  If true, systemd::service will be passed
#  ensure => present, otherwise ensure => absent.  Default: true.
#
# [*brokers*]
#   Hash of Kafka Broker configs keyed by fqdn of each kafka broker node.
#   This Hash should be of the form:
#   { 'hostA' => { 'id' => 1, 'rack' => 'A' }, 'hostB' => { 'id' => 2, 'rack' => 'B' }, ... }
#   Default: { $::fqdn => { 'id' => 1 } }
#  'rack' is optional, but will be used for broker.rack awareness.
#
# [*listeners*]
#   Array of URIs Kafka will listen on.
#   Default: ['PLAINTEXT://:9092']
#
# [*security_inter_broker_protocol*]
#   Security protocol used to communicate between brokers.  Default: undef
#
# [*ssl_keystore_location*]
#   The location of the key store file. Default: undef
#
# [*ssl_keystore_password*]
#   The store password for the key store file.  Default: undef
#
# [*ssl_key_password*]
#   The password of the private key in the key store file.  Default: undef
#
# [*ssl_truststore_location*]
#   The location of the trust store file.  Default: undef
#
# [*ssl_truststore_password*]
#   The password for the trust store file.  Default: undef
#
# [*ssl_client_auth]
#   Configures kafka broker to request client authentication.  Must be one of
#   'none', 'requested', or 'required'.  Default: undef
#
# [*ssl_enabled_protocols**]
#   Comma separated string of enabled ssl protocols that will be accepted from clients
#  e.g. TLSv1.2,TLSv1.1,TLSv1.  Default: undef
#
# [*ssl_cipher_suites*]
#   Comma separated string of cipher suites that will be accepted from clients.
#   Default: undef
#
# [*log_dirs*]
#   Array of directories in which the broker will store its received message
#   data.  Default: ['/var/spool/kafka']
#
# [*zookeeper_connect*]
#   Zookeeper URI list and chroot on which Kafka will store its metadata.
#   To use multiple hosts and a chroot, do something like
#       zk1:2181,zk2:2181,zk3:2181/kafka/chroot
#   Default: localhost:2181
#
# [*zookeeper_connection_timeout_ms*]
#   The max time that the client waits to establish a connection to zookeeper.
#   If not set, the value in zookeeper.session.timeout.ms is used.
#   Default: 6000
#
# [*zookeeper_session_timeout_ms*]
#   Zookeeper session timeout.  Default: 6000
#
# [*auto_create_topics_enable*]
#    If autocreation of topics is allowed.  Default: true
#
# [*auto_leader_rebalance_enable*]
#   If leaders should be auto rebalanced.  Default: true
#
# [*num_partitions*]
#   The default number of partitions per topic.
#   Default: 1
#
# [*default_replication_factor*]
#   The default replication factor for automatically created topics.
#   Default: 1
#
# [*delete_topic_enable*]
#   Enables topic deletion.  Default: true
#
# [*min_insync_replicas*]
#   When producing with acks=all, this specifiies the number of replicas that should be in
#   a partition's ISR.  If fewer than this are present, the produce request will fail.
#   Default: 1
#
# [*replica_lag_time_max_ms*]
#   If a follower hasn't sent any fetch requests for this window
#   of time, the leader will remove the follower from ISR.
#   Default: undef (10000)
#
# [*num_recovery_threads_per_data_dir*]
#   The number of threads per data directory to be used for log recovery at
#   startup and flushing at shutdown.  Default: undef (1)
#
# [*replica_socket_timeout_ms*]
#   The socket timeout for network requests to the leader for
#   replicating data.  Default: undef (30000)
#
# [*replica_socket_receive_buffer_bytes*]
#   The socket receive buffer for network requests to the leader
#   for replicating data.  Default: undef (65536)
#
# [*num_replica_fetchers*]
#   Number of threads used to replicate messages from leaders.
#   Default: 1
#
# [*replica_fetch_max_bytes*]
#   The number of bytes of messages to attempt to fetch for each
#   partition in the fetch requests the replicas send to the leader.
#   Default: undef (1048576)
#
# [*num_network_threads*]
#   The number of threads handling network requests.  Default: undef (3)
#
# [*num_io_threads*]
#   The number of threads doing disk I/O.  Default: size($log_dirs)
#
# [*socket_send_buffer_bytes*]
#   The byte size of the send buffer (SO_SNDBUF) used by the socket server.
#   Default: 1048576
#
# [*socket_receive_buffer_bytes*]
#   The byte size of receive buffer (SO_RCVBUF) #used by the socket server.
#   Default: 1048576
#
# [*socket_request_max_bytes*]
#   The maximum size of a request that the socket server will accept.
#   Default: undef (104857600)
#
# [*log_message_timestamp_type*]
#   Default message timestamp type for a topic if it is not set on that topic.
#   CreateTime means the timestamp will only be set if the producer provides it.
#   LogAppendTime means that the broker will set it to the time is receives the message.
#   You can override this setting per topic.  Default: LogAppendTime
#
# [*log_flush_interval_messages*]
#   The number of messages accumulated on a log partition before messages are
#   flushed to disk.  Default: 10000
#
# [*log_flush_interval_ms*]
#    The maximum amount of time a message can sit in a log before we force a
#    flush: Default 1000 (1 second)
#
# [*log_retention_hours*]
#   The number of hours to keep a log file before deleting it (in hours).
#   Default 168 (1 week)
#
# [*log_retention_bytes*]
#   The maximum size of the log before deleting it.  Default: undef
#
# [*log_segment_bytes*]
#    The maximum size of a log segment file. When this size is reached a new
#    log segment will be created:  Default undef (512MB)
#
# [*log_retention_check_interval_ms*]
#   The frequency in milliseconds that the log cleaner checks whether any log
#   eligible for deletion.  Default: undef (300000)
#
# [*log_cleanup_policy*]
#   Designates the retention policy to use on old log segments. 'delete' will
#   discard old segments when their retention time or size limit has been
#   reached. 'compact' will enable log compaction.
#   Default: delete
#
# [*offsets_retention_minutes*]
#   Log retention window in minutes for offsets topic.
#   Default: 10080   (1 week)
#
# [*log_max_backup_index*]
#   Number of (256 MB) log files to keep in /var/log/kafka.  Default: 4
#
# [*inter_broker_protocol_version*]
#   Specify which version of the inter-broker protocol will be used. This is
#   typically bumped after all brokers were upgraded to a new version. Default: undef
#
# [* group_initial_rebalance_delay*]
#   The time, in milliseconds, that the `GroupCoordinator` will delay the initial consumer rebalance.
#
# [*log_message_format_version*]
#   Specify the message format version the broker will use to append messages to the logs.
#   By setting a particular message format version, the user is certifying that all the
#   existing messages on disk are smaller or equal than the specified version.
#   Setting this value incorrectly will cause consumers with older versions to break as
#   they will receive messages with a format that they don't understand.
#   Default: undef
#
# [*nofiles_ulimit*]
#   The broker process' number of open files ulimit.
#   Default: 8192
#
# [*java_opts*]
#   Extra Java options.  Default: undef
#
# [*classpath*]
#   Extra classpath entries.  Default: undef
#
# [*jmx_port*]
#   Port on which to expose JMX metrics.  Default: 9999
#
# [*heap_opts*]
#   Heap options to pass to JVM on startup.  Default: undef
#
# [*jvm_performance_opts*]
#   Value to use for KAFKA_JVM_PERFORMANCE_OPTS in /etc/default/kafka.
#   This controls GC settings.  Default: undef.
#
# [*server_properties_template*]
#   Default: 'confluent/kafka/server.properties.erb'
#
# [*default_template*]
#   Default: 'confluent/kafka/kafka.default.erb'
#
# [*log4j_properties_template*]
#   Default: 'confluent/kafka/log4j.properties.erb'
#
# [*message_max_bytes*]
#   The maximum message size allowed.
#   Default: 1048576
#
# [*allow_everyone_if_no_acl_found*]
#   If this value is on true, only the topics on which are ACLs are set are secured.
#   Default: true
#
# [*super_users*]
#   List of super user CNs.  If configuring SSL, this should at least include the cluster's SSL
#   principal so the cluster can operate.
#
# [*authorizer_class_name*]
#   Sets up the ACL authorization provider specified
#   as parameter. It also set up a more verbose log4j logging related
#   to ACL authorization events.
#   Default: undef
#
# [*authorizer_log_level*]
#   Default: INFO
#
class confluent::kafka::broker(
    $enabled                             = true,
    $brokers                             = {
        "${::fqdn}" => {
            'id'   => 1,
            'port' => 9092,
        },
    },
    $listeners                           = ['PLAINTEXT://:9092'],

    $security_inter_broker_protocol      = undef,

    $ssl_keystore_location               = undef,
    $ssl_keystore_password               = undef,
    $ssl_key_password                    = undef,
    $ssl_truststore_location             = undef,
    $ssl_truststore_password             = undef,
    $ssl_client_auth                     = undef,
    $ssl_enabled_protocols               = undef,
    $ssl_cipher_suites                   = undef,

    $log_dirs                            = ['/var/spool/kafka'],

    $zookeeper_connect                   = 'localhost:2181',
    $zookeeper_connection_timeout_ms     = undef,
    $zookeeper_session_timeout_ms        = undef,

    $auto_create_topics_enable           = true,
    $auto_leader_rebalance_enable        = true,

    $num_partitions                      = 1,
    $default_replication_factor          = 1,
    $delete_topic_enable                 = true,
    $offsets_topic_replication_factor    = undef,
    $min_insync_replicas                 = 1,
    $replica_lag_time_max_ms             = undef,
    $num_recovery_threads_per_data_dir   = undef,
    $replica_socket_timeout_ms           = undef,
    $replica_socket_receive_buffer_bytes = undef,
    $num_replica_fetchers                = 1,
    $replica_fetch_max_bytes             = undef,

    $num_network_threads                 = undef,
    $num_io_threads                      = size($log_dirs),
    $socket_send_buffer_bytes            = 1048576,
    $socket_receive_buffer_bytes         = 1048576,
    $socket_request_max_bytes            = undef,

    $log_message_timestamp_type          = 'CreateTime',
    $log_flush_interval_messages         = undef,
    $log_flush_interval_ms               = undef,

    $log_retention_hours                 = 168,     # 1 week
    $log_retention_bytes                 = undef,
    $log_segment_bytes                   = undef,

    $log_retention_check_interval_ms     = undef,
    $log_cleanup_policy                  = undef,

    $offsets_retention_minutes           = 10080,   # 1 week

    $inter_broker_protocol_version       = undef,
    $group_initial_rebalance_delay       = undef,
    $log_message_format_version          = undef,
    $nofiles_ulimit                      = 8192,
    $java_opts                           = undef,
    $classpath                           = undef,
    $jmx_port                            = 9999,
    $heap_opts                           = undef,
    $log_max_backup_index                = 4,
    $jvm_performance_opts                = undef,

    $server_properties_template          = 'confluent/kafka/server.properties.erb',
    $default_template                    = 'confluent/kafka/kafka.default.erb',
    $log4j_properties_template           = 'confluent/kafka/log4j.properties.erb',

    $message_max_bytes                   = 1048576,

    $allow_everyone_if_no_acl_found      = true,
    $super_users                         = undef,
    $authorizer_class_name               = undef,
    $authorizer_log_level                = 'INFO',
) {
    # confluent::kafka::common installs the kafka package
    # and a handy wrapper script.
    require ::confluent::kafka::common

    # Get this broker's id out of the $kafka::brokers
    # configuration hash.
    $id = $brokers[$::fqdn]['id']

    # If this broker's rack is set, use it for broker.rack
    $rack = $brokers[$::fqdn]['rack']

    # The default Kafka port for KAFKA_BOOTSTRAP_SERVERS will be the port
    # first port specified in the $listeners array.  This is used
    # in the kafka shell wrapper to automatically provide broker list.
    $default_port = inline_template("<%= Array(@listeners)[0].split(':')[-1] %>")

    # Local variable for rendering in templates.
    $java_home = $::confluent::kafka::common::java_home

    # This is the message data directory,
    # not to be confused with /var/log/kafka
    # which contains daemon process logs.
    file { $log_dirs:
        ensure => 'directory',
        owner  => 'kafka',
        group  => 'kafka',
        mode   => '0755',
    }

    # If any passwords, set proper readability.
    if $ssl_key_password or $ssl_keystore_password or $ssl_truststore_password {
        $server_properties_mode = '0440'
    }
    else {
        $server_properties_mode = '0444'
    }
    # Render out Kafka Broker config files.
    file { '/etc/kafka/server.properties':
        content => template($server_properties_template),
        group   => 'kafka',
        mode    => $server_properties_mode,
    }

    # log4j configuration for Kafka daemon
    # process logs in /var/log/kafka.
    file { '/etc/kafka/log4j.properties':
        content => template($log4j_properties_template),
    }

    # Environment variables that are passed to kafka-run-class.
    file { '/etc/default/kafka':
        content => template($default_template),
    }

    # Environment variables used by the /usr/local/bin/kafka wrapper script
    # installed by confluent::kafka::common.  This makes it easier
    # to use the kafka wrapper script on Kafka brokers.
    file { '/etc/profile.d/kafka.sh':
        content => template('confluent/kafka/kafka-profile.sh.erb'),
    }

    $service_ensure = $enabled ? {
        false   => 'absent',
        default => 'present',
    }

    # Start the Kafka server.
    # We don't want to subscribe to the config files here.
    # It will be better to manually restart Kafka when
    # the config files changes.
    systemd::service { 'kafka':
        ensure  => $service_ensure,
        content => systemd_template('kafka'),
        require => [
            File[$log_dirs],
            File['/etc/kafka/server.properties'],
            File['/etc/kafka/log4j.properties'],
            File['/etc/default/kafka'],
        ],
    }
}
