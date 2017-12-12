# === class profile::cache::kafka::webrequest::duplicate
#
# Sets up a varnishkafka instance producing varnish
# webrequest logs to the analytics Jumbo brokers in eqiad.
# This is a temporary profile to test the new Kafka cluster before switching
# real production traffic to it.
#
# === Parameters
#
# [*cache_cluster*]
#   the name of the cache cluster
#
# [*statsd_host*]
#   the host to send statsd data to.
#
class profile::cache::kafka::webrequest::duplicate(
    $cache_cluster     = hiera('cache::cluster'),
    $statsd_host       = hiera('statsd'),
    $ssl_key_password  = hiera('profile::cache::kafka::webrequest::duplicate::ssl_key_password', undef),
) {
    $config = kafka_config('jumbo-eqiad')
    # NOTE: This is used by inheriting classes role::cache::kafka::*
    $kafka_brokers = $config['brokers']['array']

    $topic = "webrequest_${cache_cluster}"
    # These used to be parameters, but I don't really see why given we never change
    # them
    $varnish_name           = 'frontend'
    $varnish_svc_name       = 'varnish-frontend'
    $kafka_protocol_version = '0.9.0.1'

    # For any info about the following settings, please check
    # profile::cache::kafka::webrequest.
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

    # TLS/SSL configuration
    $ssl_ca_location = '/etc/ssl/certs/Puppet_Internal_CA.pem'
    $ssl_location = '/etc/varnishkafka/ssl'
    $ssl_location_private = '/etc/varnishkafka/ssl/private'

    $ssl_key_location_secrets_path = 'certificates/varnishkafka/varnishkafka.key.pem'
    $ssl_key_location = "${ssl_location_private}/varnishkafka.key.pem"

    $ssl_certificate_secrets_path = 'certificates/varnishkafka/varnishkafka.key.public.pem'
    $ssl_certificate_location = "${ssl_location}/varnishkafka.key.public.pem"

    file { $ssl_location_private:
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0500',
    }

    file { $ssl_key_location:
        content => secret($ssl_key_location_secrets_path),
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        require => File[$ssl_location_private],
    }

    file { $ssl_certificate_location:
        content => secret($ssl_certificate_secrets_path),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }

    varnishkafka::instance { 'webrequest-jumbo-duplicate':
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
        #TLS/SSL config
        ssl_enabled                  => true,
        ssl_ca_location              => $ssl_ca_location,
        ssl_key_password             => $ssl_key_password,
        ssl_key_location             => $ssl_key_location,
        ssl_certificate_location     => $ssl_certificate_location,
        require                      => [
            File[$ssl_key_location],
            File[ssl_certificate_location]
        ],
    }

    # Make sure varnishes are configured and started for the first time
    # before the instances as well, or they fail to start initially...
    Service <| tag == 'varnish_instance' |> -> Varnishkafka::Instance['webrequest-jumbo-duplicate']

}
