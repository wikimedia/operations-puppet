# == Class role::cache::kafka::webrequest
# Sets up a varnishkafka instance producing varnish
# webrequest logs to the analytics Kafka brokers in eqiad.
#
# == Parameters
# $topic            - the name of kafka topic to which to send messages
# $varnish_name - the name of the varnish instance to read shared logs from.  Default 'frontend'
# $varnish_svc_name - the name of the init unit for the above, default 'varnish-frontend'
#
class role::cache::kafka::webrequest(
    $topic,
    $varnish_name = 'frontend',
    $varnish_svc_name = 'varnish-frontend'
) inherits role::cache::kafka
{
    varnishkafka::instance { 'webrequest':
        brokers                      => $kafka_brokers,
        topic                        => $topic,
        format_type                  => 'json',
        compression_codec            => 'snappy',
        varnish_name                 => $varnish_name,
        varnish_svc_name             => $varnish_svc_name,
        # Note: fake_tag tricks varnishkafka into allowing hardcoded string into a JSON field.
        # Hardcoding the $fqdn into hostname rather than using %l to account for
        # possible slip ups where varnish only writes the short hostname for %l.
        format                       => "%{fake_tag0@hostname?${::fqdn}}x %{@sequence!num?0}n %{%FT%T@dt}t %{Varnish:time_firstbyte@time_firstbyte!num?0.0}x %{X-Client-IP@ip}o %{Varnish:handling@cache_status}x %{@http_status}s %{@response_size!num?0}b %{@http_method}m %{Host@uri_host}i %{@uri_path}U %{@uri_query}q %{Content-Type@content_type}o %{Referer@referer}i %{User-Agent@user_agent}i %{Accept-Language@accept_language}i %{X-Analytics@x_analytics}o %{Range@range}i %{X-Cache@x_cache}o",
        message_send_max_retries     => 3,
        # At ~6000 msgs per second, 500000 messages is over 1 minute
        # of buffering, which should be more than enough.
        queue_buffering_max_messages => 500000,
        # bits varnishes can do about 6000 reqs / sec each.
        # We want to send batches at least once a second.
        batch_num_messages           => 6000,
        # On caches with high traffic (bits and upload), we have seen
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
    }

    if $::standard::has_ganglia {
        varnishkafka::monitor { 'webrequest':
            # The primary webrequest varnishkafka instance was formerly the
            # only one running, so we don't prefix its Ganglia metric keys.
            key_prefix => '',
        }
    }

    # Generate icinga alert if varnishkafka is not running.
    nrpe::monitor_service { 'varnishkafka':
        description  => 'Varnishkafka log producer',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1: -C varnishkafka',
        require      => Class['::varnishkafka'],
    }

    # Extract cache type name from topic for use in statsd prefix.
    # There is probably a better way to do this.
    $cache_type = regsubst($topic, '^webrequest_(.+)$', '\1')
    $graphite_metric_prefix = "varnishkafka.${::hostname}.webrequest.${cache_type}"

    # Test using logster to send varnishkafka stats to statsd -> graphite.
    # This may be moved into the varnishkafka module.
    logster::job { 'varnishkafka-webrequest':
        minute          => '*/1',
        parser          => 'JsonLogster',
        logfile         => '/var/cache/varnishkafka/webrequest.stats.json',
        logster_options => "-o statsd --statsd-host=statsd.eqiad.wmnet:8125 --metric-prefix=${graphite_metric_prefix}",
    }


    # TEMPORARY test --until on all vk drerr alerts
    $until = '0min'

    # Generate an alert if too many delivery report errors per minute
    # (logster only reports once a minute)
    monitoring::graphite_threshold { 'varnishkafka-kafka_drerr':
        description     => 'Varnishkafka Delivery Errors per minute',
        metric          => "derivative(transformNull(${graphite_metric_prefix}.varnishkafka.kafka_drerr, 0))",
        # More than 0 errors is warning threshold.
        warning         => 0,
        # More than 20000 errors is critical threshold.
        critical        => 20000,
        # But only alert if a large percentage of the examined datapoints
        # are over the threshold.
        percentage      => 80,
        from            => '10min',
        until           => $until,
        nagios_critical => false,
        require         => Logster::Job['varnishkafka-webrequest'],
        ensure          => 'present',
    }

    # Use graphite_anomaly to alert about anomolous deliver errors.
    monitoring::graphite_anomaly { 'varnishkafka-anomaly-kafka_drerr':
        description     => 'Varnishkafka Delivery Errors per minute anomaly',
        metric          => "nonNegativeDerivative(transformNull(${graphite_metric_prefix}.varnishkafka.kafka_drerr, 0))",
        over            => true,
        # warn if more than 10 anomylous datapoints (last 10 minutes)
        warning         => 5,
        # critical if more than 45 anomylous datapoints (last 45 minutes)
        critical        => 45,
        nagios_critical => false,
        require         => Logster::Job['varnishkafka-webrequest'],
        # Disabling this.  It doesn't work like I wanted it to.
        ensure          => 'absent',
    }
}
