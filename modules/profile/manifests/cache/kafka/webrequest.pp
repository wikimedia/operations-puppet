# SPDX-License-Identifier: Apache-2.0
# === class profile::cache::kafka::webrequest
#
# Sets up a varnishkafka instance producing varnish
# webrequest logs to a Kafka cluster.
#
# === Parameters
#
# [*cache_cluster*]
#   The name of the cache cluster.
#
# [*kafka_cluster_name*]
#   Name of the Kafka cluster in the hiera kafka_clusters hash.  This can
#   be unqualified (without DC suffix) or fully qualified.
#
# [*ssl_enabled*]
#   If true, the Kafka cluster needs to be configured with SSL support.
#   profile::cache::kafka::certificate will be included, and certs used from it.
#   Default: false
#
# [*monitoring_enabled*]
#   True if the varnishkafka instance should be monitored.  Default: false
#
class profile::cache::kafka::webrequest(
    String $cache_cluster       = lookup('cache::cluster'),
    String $kafka_cluster_name  = lookup('profile::cache::kafka::webrequest::kafka_cluster_name'),
    Boolean $ssl_enabled        = lookup('profile::cache::kafka::webrequest::ssl_enabled', {'default_value' => false}),
    Boolean $monitoring_enabled = lookup('profile::cache::kafka::webrequest::monitoring_enabled', {'default_value' => false}),
    Boolean $atskafka_enabled   = lookup('profile::cache::kafka::webrequest::atskafka_enabled', {'default_value' => false}),
) {
    $kafka_config     = kafka_config($kafka_cluster_name)

    $topic            = "webrequest_${cache_cluster}"
    $varnish_name     = 'frontend'
    $varnish_svc_name = 'varnish-frontend'

    # Background task: T136314
    # Background info about the parameters used:
    # 'q':
    # 1) Filter out PURGE requests and Pipe creation traffic.
    # 2) A Varnish log containing Timestamp:Pipe does not carry Timestamp:Resp,
    # used by Analytics to bucket data on Hadoop and for data consistency
    # checks. These requests indicate that Varnish tried to establish a pipe
    # channel between the client and the backend, an information that
    # can be discarded.
    # Websockets upgrade usually lead to long lived requests that trigger
    # VSL timeouts as well. Varnishkafka does not have a nice support for
    # these use cases, moreover we haven't decided yet if weberequest logs
    # will need to take them into account or not.
    # At the moment these requests get logged incorrectly and with partial
    # data (due to the VSL timeout) so it makes sense to filter them out to
    # remove noise from Analytics data.
    # 3) A request marked with the VSL tag 'HttpGarbage' indicates unparseable
    # HTTP requests, generating spurious Varnish logs.
    # 4) After T27611 Varnish has the capability of trying to fetch .webp
    # variants of the hottest thumbnails, but this adds extra log entries
    # to the shared memory log that pollutes webrequests. Every log containing
    # Timestamp:Restart (and hence not Timestamp:Resp) need to be filtered out,
    # since it represents a failed fetch for the webp variant (not yet generated
    # for example) that is followed by a 'regular' fetch for the original image.
    #
    # 'T':
    # VLS API timeout is the maximum time that Varnishkafka will wait between
    # "Begin" and "End" timestamps before flushing the available tags to a log.
    # When a timeout occurs most of the times the result is a webrequest log
    # missing values like the end timestamp.
    #
    # VSL Timeout parameters modified during the upload migration:
    # 'L':
    # Sets the upper limit of incomplete transactions kept before the oldest
    # one is force completed. This setting keeps an upper bound
    # on the memory usage of running queries (Default: 1000).
    # A change in the -T timeout value has the side effect of keeping more
    # incomplete transactions in memory for each varnishkafka query (in our case
    # it directly corresponds to a varnishkafka instance running).
    # The threshold has been raised to '5000' the first time (which removed
    # the bulk of the timeouts) and to '10000' the second time.
    # 'T':
    # Raised the maximum timeout for incomplete records from '700' to '1500'
    # after setting the -L to '5000'. VSL timeouts were masked
    # by VSL store overflow errors.

    $varnish_opts = {
        'q' => 'ReqMethod ne "PURGE" and not Timestamp:Pipe and not Timestamp:Restart and not ReqHeader:Upgrade ~ "[wW]ebsocket" and not HttpGarbage',
        'T' => '1500',
        'L' => '10000'
    }

    # Note: the newer version of Varnishkafka (compatible with Varnish 4)
    # needs to specify if the timestamp formatter should output the time
    # when the request started to be processed by Varnish (SLT_Timestamp Start)
    # or the time of the response flush (SLT_Timestamp Resp).
    # The "end:" prefix forces the latter and it is not be part of the final output.
    $timestamp_formatter = '%{end:%FT%TZ@dt}t'

    # estimated peak reqs/sec we need to reasonably handle on a single cache.
    # The current maximal "reasonable" case is in the text cluster, where if we
    # have mutiple DCs depooled in DNS and ~8 servers in the remaining DC to
    # split traffic, we could peak at ~9000
    $peak_rps_estimate = 9000

    if $ssl_enabled {
        $kafka_brokers = $kafka_config['brokers']['ssl_array']

        include profile::cache::kafka::certificate

        # Include this class to get key and certificate for varnishkafka
        # to produce to Kafka over SSL/TLS.
        $ssl_ca_location = $profile::cache::kafka::certificate::ssl_ca_location
        $ssl_cipher_suites = $profile::cache::kafka::certificate::ssl_cipher_suites
        $ssl_curves_list = $profile::cache::kafka::certificate::ssl_curves_list
        $ssl_sigalgs_list = $profile::cache::kafka::certificate::ssl_sigalgs_list
        $ssl_keystore_password = $profile::cache::kafka::certificate::ssl_key_password
        $ssl_key_password = $profile::cache::kafka::certificate::ssl_key_password
        $ssl_key_location = $profile::cache::kafka::certificate::ssl_key_location
        $ssl_certificate_location = $profile::cache::kafka::certificate::ssl_certificate_location
    }
    else {
        $kafka_brokers = $kafka_config['brokers']['array']

        $ssl_ca_location = undef
        $ssl_key_password = undef
        $ssl_key_location = undef
        $ssl_certificate_location = undef
        $ssl_cipher_suites = undef
        $ssl_curves_list = undef
        $ssl_sigalgs_list = undef
        $ssl_keystore_password = undef
    }

    varnishkafka::instance { 'webrequest':
        brokers                      => $kafka_brokers,
        topic                        => $topic,
        format_type                  => 'json',
        compression_codec            => 'snappy',
        varnish_name                 => $varnish_name,
        varnish_svc_name             => $varnish_svc_name,
        varnish_opts                 => $varnish_opts,
        # Note: fake_tag tricks varnishkafka into allowing hardcoded string into a JSON field.
        # Hardcoding the $fqdn into hostname rather than using %l to account for
        # possible slip ups where varnish only writes the short hostname for %l.
        format                       => "%{fake_tag0@hostname?${::fqdn}}x %{@sequence!num?0}n ${timestamp_formatter} %{Varnish:time_firstbyte@time_firstbyte!num?0.0}x %{X-Client-IP@ip}o %{X-Cache-Status@cache_status}o %{@http_status}s %{@response_size!num?0}b %{@http_method}m %{Host@uri_host}i %{@uri_path}U %{@uri_query}q %{Content-Type@content_type}o %{Referer@referer}i %{User-Agent@user_agent}i %{Accept-Language@accept_language}i %{X-Analytics@x_analytics}o %{Range@range}i %{X-Cache@x_cache}o %{Accept@accept}i %{Server@backend}o %{VCL_Log:tls@tls}x",
        message_send_max_retries     => 3,
        # Buffer up to 80s at our expected maximum reasonable rate
        queue_buffering_max_messages => 80 * $peak_rps_estimate,
        # Our aim here is to not send batches more often than once per second,
        # given our expected maximum reasonable rate
        batch_num_messages           => $peak_rps_estimate,
        # On caches with high traffic (text and upload), we have seen
        # message drops from esams during high load time with a large
        # request ack timeout (it was 30 seconds).
        # The vanrishkafka buffer gets too full and it drops messages.
        # Perhaps this is a buffer bloat problem.
        # Note that varnishkafka will retry a timed-out produce request.
        topic_request_timeout_ms     => 2000,
        # 1 means only the leader broker must ACK each produce request
        topic_request_required_acks  => '1',
        # Write out stats to varnishkafka.stats.json
        # this often.  This is set at 15 so that
        # stats will be fresh when polled from gmetad.
        log_statistics_interval      => 15,
        #TLS/SSL config
        ssl_enabled                  => $ssl_enabled,
        ssl_ca_location              => $ssl_ca_location,
        ssl_key_password             => $ssl_key_password,
        ssl_key_location             => $ssl_key_location,
        ssl_certificate_location     => $ssl_certificate_location,
        ssl_cipher_suites            => $ssl_cipher_suites,
        ssl_curves_list              => $ssl_curves_list,
        ssl_sigalgs_list             => $ssl_sigalgs_list,
        ssl_keystore_location        => undef,
        ssl_keystore_password        => $ssl_keystore_password,
    }

    if $atskafka_enabled {
        atskafka::instance { 'webrequest':
            brokers               => $kafka_brokers,
            topic                 => "atskafka_test_${topic}",
            stats_interval_ms     => 60000,
            # Instead of sending messages every 5 milliseconds (the default),
            # buffer locally and send once every 2 seconds. Having chosen 2s
            # here, the amount of messages sent per batch is 2x the number of
            # rps served by the ATS instance divided by the number of kafka
            # partitions for the topic. Larger batches benefit from better
            # compression and less overhead improving throughput at the expense
            # of latency.
            buffering_ms          => 2000,
            # Instead of waiting for all replicas to commit the message
            # (default value -1), wait for the leader only.
            request_required_acks => 1,
            socket                => '/srv/trafficserver/tls/var/run/analytics.sock',
            tls                   => {
                ca_location          => $ssl_ca_location,
                key_location         => $ssl_key_location,
                key_password         => $ssl_key_password,
                certificate_location => $ssl_certificate_location,
                cipher_suites        => $ssl_cipher_suites,
                curves_list          => $ssl_curves_list,
                sigalgs_list         => $ssl_sigalgs_list,
            },
        }
    }

    if $monitoring_enabled {
        # Aggregated alarms for delivery errors are defined in icinga::monitor::analytics

        # Generate icinga alert if varnishkafka is not running.
        nrpe::monitor_service { 'varnishkafka-webrequest':
            description   => 'Webrequests Varnishkafka log producer',
            nrpe_command  => "/usr/lib/nagios/plugins/check_procs -c 1:1 -a '/usr/bin/varnishkafka -S /etc/varnishkafka/webrequest.conf'",
            contact_group => 'admins,analytics,team-data-platform',
            require       => Class['::varnishkafka'],
            notes_url     => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Varnishkafka',
        }
    }

    # Make sure varnishes are configured and started for the first time
    # before the instances as well, or they fail to start initially...
    Service <| tag == 'varnish_instance' |> -> Varnishkafka::Instance['webrequest']

}
