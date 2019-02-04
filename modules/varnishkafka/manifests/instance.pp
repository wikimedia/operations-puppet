# == Class varnishkafka
# Configures and runs varnishkafka Varnish to Kafka producer.
# See: https://github.com/wikimedia/varnishkafka
# Most varnishkafka.conf properties are supported.
#
# == Parameters
# $brokers                          - Array of Kafka broker host:ports.
#                                     Default: [localhost:9091]
# $topic                            - Kafka topic name to produce to.
#                                     Default: varnish
# $sequence_number                  - Sequence number at which to start logging.
#                                     You can set this to an arbitrary integer, or to
#                                     'time', which will start the sequence number
#                                     at the current timestamp * 10000000. Default: 0
# $output                           - output type.  Either 'kafka', 'stdout', or 'null'.
#                                     Default: kafka
# $format_type                      - Log format type.  Either 'string' or 'json'
#                                     Default: string
# $format                           - Log format string.
# $format_key_type                  - Kafka message key format type.
#                                     Either 'string' or 'json'.  Default: string
# $format_key                       - Kafka message key format string.
#                                     Default: undef (disables Kafka message key usage).
# $partition                        - Topic partition number to send to.  -1 for random.
#                                     Default: -1
# $queue_buffering_max_messages     - Maximum number of messages allowed on the
#                                     local Kafka producer queue.  Default: 100000
# $queue_buffering_max_ms           - Maximum time, in milliseconds, for buffering
#                                     data on the producer queue.  Default: 1000
# $batch_num_messages               - Maximum number of messages batched in one MessageSet.
#                                     Default: 1000
# $message_send_max_retries         - Maximum number of retries per messageset.
#                                     Default: 3
# $topic_request_required_acks      - Required ack level.  Default: 1
# $topic_message_timeout_ms         - Local message timeout (milliseconds).
#                                     Default: 300000
# $topic_request_timeout_ms         - Ack timeout of the produce request.
#                                     Default: 5000
# $socket_send_buffer_bytes         - SO_SNDBUFF Socket send buffer size. System default is used if 0.
#                                     Default: 0
# $compression_codec                - Compression codec to use when sending batched messages to
#                                     Kafka.  Valid values are 'none', 'gzip', and 'snappy'.
#                                     Default: none
# $varnish_name                     - Name of varnish instance to log from in varnish terms (e.g.
#                                     the -n argument to various CLI commands).  Default: undef,
#                                     typically "frontend", or "$::hostname".
# $varnish_svc_name                 - Name of varnish *service* to log from, as named by the init system.
#                                     Default: undef, typically "varnish-frontend" or "varnish"
# $varnish_opts                     - Arbitrary hash of varnish CLI options.
#                                     Default: { 'm' => 'RxRequest:^(?!PURGE$)' }
# $tag_size_max                     - Maximum size of an individual field.  Field will be truncated
#                                     if it is larger than this.  Default: 2048
# $logline_line_scratch_size        - Size of static log line buffer.  If a line is larger than
#                                     this buffer, temp buffers will be allocated.  Set this
#                                     slighly larger than your expected line size.
#                                     Default: 4096
# $logline_hash_size                - Number of hash buckets.  Set this to avg_requests_per_second / 5.
#                                     Default: 5000 - Usable only with Varnish 3
# $logline_hash_max                 - Max number of log lines / bucket.  Set this to
#                                     avg_requests_per_second / $log_hash_size.
#                                     Default: 5 - Usable only with Varnish 3
# $logline_data_copy                - If true, log tag data read from VSL files
#                                     should be copied instantly when read.  Default true.
# $log_level                        - varnishkafka log level.  Default 6 (info).
# $log_stderr                       - Boolean.  Whether to log to stderr.  Default: true
# $log_syslog                       - Boolean.  Whether to log to syslog.  Default: true
# $log_statistics_file              - Path to varnishkafka JSON statistics file.
#                                     Default: /var/cache/varnishkafka/varnishkafka.stats.json
# $log_statistics_interval          - JSON statistics file output interval in seconds.  Default: 60
#
# $should_subscribe                 - If true, the varnishkafka service will restart for config
#                                     changes.  Default: true.
# $conf_template
#
# $force_protocol_version           - The Kafka protocol version used to produce events.
#                                     Suggested workaround for https://issues.apache.org/jira/browse/KAFKA-3547
#                                     (Kafka 0.9.0.[0,1] protocol versions affected)
#
# $ssl_enabled                      - enable the TLS/SSL section of the v4 configuration file.
#                                     Default: false
#
# $ssl_ca_location                  - CA certificate's path or simply the certificate
#                                     of the entity that signed and that is able to verify
#                                     the client's key.
#                                     Default: undef
#
# $ssl_key_password                 - Password of the SSL client key.
#                                     Default: undef
#
# $ssl_key_location                 - Full path of the SSL client Key.
#                                     Default: undef
#
# $ssl_certificate_location         - Full path of the SSL client certificate.
#                                     Default: undef
#
# $ssl_cipher_suites                - Comma separated string of cipher suites that are permitted to
#                                     be used for SSL communication with brokers.  This must match
#                                     at least one of the cipher suites allowed by the brokers.
#
# $ssl_curves_list                  - Colon separated string of supported curves/named groups.
#                                     This must match at least one of the named groups supported
#                                      by the broker. More details in SSL_CTX_set1_curves_list(3)
#
# $ssl_sigalgs_list                 - Colon separared string of supported signature algorithms.
#                                     This must match at least one of the signature algorithms
#                                     supported by the broker. More details in SSL_set1_client_sigalgs(3)
define varnishkafka::instance(
    $brokers                        = ['localhost:9092'],
    $topic                          = 'varnish',
    $sequence_number                = 0,
    $output                         = 'kafka',
    $format_type                    = 'string',
    $format                         = '%l	%n	%t	%{Varnish:time_firstbyte}x	%h	%{Varnish:handling}x/%s	%b	%m	http://%{Host}i%U%q	-	%{Content-Type}o	%{Referer}i	%{X-Forwarded-For}i	%{User-agent!escape}i	%{Accept-Language}i',
    $format_key_type                = 'string',
    $format_key                     = undef,

    $partition                      = -1,
    $queue_buffering_max_messages   = 100000,
    $queue_buffering_max_ms         = 1000,
    $batch_num_messages             = 1000,
    $message_send_max_retries       = 3,
    $topic_request_required_acks    = 1,
    $topic_message_timeout_ms       = 300000,
    $topic_request_timeout_ms       = 5000,
    $socket_send_buffer_bytes       = 0,
    $compression_codec              = 'none',

    $varnish_name                   = undef,
    $varnish_svc_name               = undef,
    $varnish_opts                   = { 'm' => 'RxRequest:^(?!PURGE$)', },

    $tag_size_max                   = 2048,
    $logline_scratch_size           = 4096,
    $logline_hash_size              = 5000,
    $logline_hash_max               = 5,
    $logline_data_copy              = true,

    $log_level                      = 6,
    $log_stderr                     = false,
    $log_syslog                     = true,
    $log_statistics_file            = "/var/cache/varnishkafka/${name}.stats.json",
    $log_statistics_interval        = 60,

    $should_subscribe               = true,
    $conf_template                  = 'varnishkafka/varnishkafka.conf.erb',
    $force_protocol_version         = undef,

    $ssl_enabled                    = false,
    $ssl_ca_location                = undef,
    $ssl_key_password               = undef,
    $ssl_key_location               = undef,
    $ssl_certificate_location       = undef,
    $ssl_cipher_suites              = undef,
    $ssl_curves_list                = undef,
    $ssl_sigalgs_list               = undef,
) {
    require ::varnishkafka

    # A more restrictive set of reading permissions
    # is deployed if SSL is configured, since the key's password
    # will be stored in the instance config.
    $instance_conf_mode = $ssl_enabled ? {
        true    => '0400',
        default => '0444',
    }

    file { "/etc/varnishkafka/${name}.conf":
        content => template($conf_template),
        owner   => 'root',
        group   => 'root',
        mode    => $instance_conf_mode,
        require => Package['varnishkafka'],
    }

    file { "/etc/logrotate.d/varnishkafka-${name}-stats":
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('varnishkafka/varnishkafka-stats.logrotate.erb'),
        require => Package['varnishkafka'],
    }

    base::service_unit { "varnishkafka-${name}":
        systemd        => systemd_template('varnishkafka'),
        refresh        => $should_subscribe,
        require        => Package['varnishkafka'],
        service_params => {
            enable     => true,
            hasstatus  => true,
            hasrestart => true,
        }
    }

    if $should_subscribe {
        File["/etc/varnishkafka/${name}.conf"] ~> Service["varnishkafka-${name}"]
        Service[$varnish_svc_name] ~> Service["varnishkafka-${name}"]
    }
    else {
        File["/etc/varnishkafka/${name}.conf"] -> Service["varnishkafka-${name}"]
        Service[$varnish_svc_name] -> Service["varnishkafka-${name}"]
    }
}
