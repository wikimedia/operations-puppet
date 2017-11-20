# === class profile::cache::kafka::webrequest
#
# Sets up a varnishkafka instance producing varnish
# webrequest logs to the analytics Kafka brokers in eqiad.
#
# === Parameters
#
# [*cache_cluster*]
#   the name of the cache cluster
#
# [*statsd_host*]
#   the host to send statsd data to.
#
class profile::cache::kafka::webrequest(
    $cache_cluster = hiera('cache::cluster'),
    $statsd_host = hiera('statsd'),
) {
    $config = kafka_config('analytics')
    # NOTE: This is used by inheriting classes role::cache::kafka::*
    $kafka_brokers = $config['brokers']['array']

    $topic = "webrequest_${cache_cluster}"
    # These used to be parameters, but I don't really see why given we never change
    # them
    $varnish_name           = 'frontend'
    $varnish_svc_name       = 'varnish-frontend'
    $kafka_protocol_version = '0.9.0.1'

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
        'q' => 'ReqMethod ne "PURGE" and not Timestamp:Pipe and not ReqHeader:Upgrade ~ "[wW]ebsocket" and not HttpGarbage',
        'T' => '1500',
        'L' => '10000'
    }
    $conf_template = 'varnishkafka/varnishkafka_v4.conf.erb'

    # Note: the newer version of Varnishkafka (compatible with Varnish 4)
    # needs to specify if the timestamp formatter should output the time
    # when the request started to be processed by Varnish (SLT_Timestamp Start)
    # or the time of the response flush (SLT_Timestamp Resp).
    # The "end:" prefix forces the latter and it is not be part of the final output.
    $timestamp_formatter = '%{end:%FT%T@dt}t'

    # estimated peak reqs/sec we need to reasonably handle on a single cache.
    # The current maximal "reasonable" case is in the text cluster, where if we
    # have mutiple DCs depooled in DNS and ~8 servers in the remaining DC to
    # split traffic, we could peak at ~9000
    $peak_rps_estimate = 9000

    varnishkafka::instance { 'webrequest':
        # FIXME - top-scope var without namespace, will break in puppet 2.8
        # lint:ignore:variable_scope
        brokers                      => $kafka_brokers,
        # lint:endignore
        topic                        => $topic,
        format_type                  => 'json',
        compression_codec            => 'snappy',
        varnish_name                 => $varnish_name,
        varnish_svc_name             => $varnish_svc_name,
        varnish_opts                 => $varnish_opts,
        # Note: fake_tag tricks varnishkafka into allowing hardcoded string into a JSON field.
        # Hardcoding the $fqdn into hostname rather than using %l to account for
        # possible slip ups where varnish only writes the short hostname for %l.
        format                       => "%{fake_tag0@hostname?${::fqdn}}x %{@sequence!num?0}n ${timestamp_formatter} %{Varnish:time_firstbyte@time_firstbyte!num?0.0}x %{X-Client-IP@ip}o %{X-Cache-Status@cache_status}o %{@http_status}s %{@response_size!num?0}b %{@http_method}m %{Host@uri_host}i %{@uri_path}U %{@uri_query}q %{Content-Type@content_type}o %{Referer@referer}i %{User-Agent@user_agent}i %{Accept-Language@accept_language}i %{X-Analytics@x_analytics}o %{Range@range}i %{X-Cache@x_cache}o",
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
        conf_template                => $conf_template,
        force_protocol_version       => $kafka_protocol_version,
    }

    # Generate icinga alert if varnishkafka is not running.
    nrpe::monitor_service { 'varnishkafka-webrequest':
        description   => 'Webrequests Varnishkafka log producer',
        nrpe_command  => "/usr/lib/nagios/plugins/check_procs -c 1 -a '/usr/bin/varnishkafka -S /etc/varnishkafka/webrequest.conf'",
        contact_group => 'admins,analytics',
        require       => Class['::varnishkafka'],
    }

    $graphite_metric_prefix = "varnishkafka.${::hostname}.webrequest.${cache_cluster}"

    # Sets up Logster to read from the Varnishkafka instance stats JSON file
    # and report metrics to statsd.
    varnishkafka::monitor::statsd { 'webrequest':
        graphite_metric_prefix => $graphite_metric_prefix,
        statsd_host_port       => $statsd_host,
    }

    # Generate an alert if too many delivery report errors per minute
    # (logster only reports once a minute)
    monitoring::graphite_threshold { 'varnishkafka-kafka_drerr':
        ensure          => 'present',
        description     => 'Varnishkafka Delivery Errors per minute',
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/varnishkafka?panelId=20&fullscreen&orgId=1'],
        metric          => "derivative(transformNull(${graphite_metric_prefix}.varnishkafka.kafka_drerr, 0))",
        warning         => 0,
        critical        => 5000,
        # But only alert if a large percentage of the examined datapoints
        # are over the threshold.
        percentage      => 80,
        from            => '10min',
        require         => Logster::Job['varnishkafka-webrequest'],
    }
    # Make sure varnishes are configured and started for the first time
    # before the instances as well, or they fail to start initially...
    Service <| tag == 'varnish_instance' |> -> Varnishkafka::Instance['webrequest']

}
