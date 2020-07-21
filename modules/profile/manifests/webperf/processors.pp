# == Class: profile::webperf::processors
#
# Provision the webperf data processors. Consumes from Kafka (incl. EventLogging),
# and produces to StatsD and Graphite.
#
# Contact: performance-team@wikimedia.org
# See also: <https://wikitech.wikimedia.org/wiki/Webperf>
#
# Services:
#
# - statsv
# - navtiming
# - coal
#
class profile::webperf::processors(
    String              $statsd                = lookup('statsd'),
    Stdlib::Fqdn        $graphite_host         = lookup('graphite_host'),
    Array[Stdlib::Fqdn] $prometheus_nodes      = lookup('prometheus_nodes'),
    Boolean             $monitor_timing_beacon_disabled = lookup('profile::webperf::processors::monitor_timing_beacon', {'default_value' => false}),
){

    $statsd_parts = split($statsd, ':')
    $statsd_host = $statsd_parts[0]
    $statsd_port = 0 + $statsd_parts[1]

    # statsv is on main kafka, not analytics or jumbo kafka.
    # Note that at any given time, all statsv varnishkafka producers are
    # configured to send to only one kafka cluster (usually main-eqiad).
    # statsv in an inactive datacenter will not process any messages, as
    # varnishkafka will not produce any messages to that DC's kafka cluster.
    # This is configured by the value of the hiera param
    # profile::cache::kafka::statsv::kafka_cluster_name when the statsv varnishkafka
    # profile is included (as of this writing on text caches).
    $kafka_main_config = kafka_config('main')
    $kafka_main_brokers = $kafka_main_config['brokers']['string']
    # Consume statsd metrics from Kafka and emit them to statsd.
    class { '::webperf::statsv':
        kafka_brokers     => $kafka_main_brokers,
        kafka_api_version => $kafka_main_config['api_version'],
        statsd_host       => '127.0.0.1',  # relay through statsd_exporter
        statsd_port       => 9112,
    }
    class { 'profile::prometheus::statsd_exporter': }

    # EventLogging is on the jumbo kafka. Unlike the main one, this
    # is not yet mirrored to other data centers, so for prod,
    # assume eqiad.
    $kafka_config  = kafka_config('jumbo', 'eqiad')
    $kafka_brokers = $kafka_config['brokers']['string']

    # Aggregate client-side latency measurements collected via the
    # NavigationTiming MediaWiki extension and send them to Graphite.
    # See <https://www.mediawiki.org/wiki/Extension:NavigationTiming>
    class { '::webperf::navtiming':
        kafka_brokers => $kafka_brokers,
        statsd_host   => $statsd_host,
        statsd_port   => $statsd_port,
    }

    # navtiming exports Prometheus metrics on port 9230.
    if $::realm == 'labs' {
        $ferm_srange = '$LABS_NETWORKS'
    } else {
        $prometheus_ferm_nodes = join($prometheus_nodes, ' ')
        $ferm_srange = "(@resolve((${prometheus_ferm_nodes})) @resolve((${prometheus_ferm_nodes}), AAAA))"
    }
    ferm::service { 'prometheus-navtiming-exporter':
        proto  => 'tcp',
        port   => '9230',
        srange => $ferm_srange,
    }

    $monitor_beacon_ensure = $monitor_timing_beacon_disabled ? {
      true  => 'absent',
      false => 'present',
    }

    monitoring::check_prometheus { 'webperf-navtiming-latest-handled':
        ensure          => $monitor_beacon_ensure,
        description     => "too long since latest timing beacon in ${::site}",
        query           => 'time() - min(webperf_latest_handled_time_seconds)',
        method          => 'gt',
        warning         => 900,   # 15 minutes; <60 seconds is normal
        critical        => 86400, # 1 day
        prometheus_url  => "http://prometheus.svc.${::site}.wmnet/ops",
        contact_group   => 'team-performance',
        dashboard_links => ['https://grafana.wikimedia.org/d/000000143/navigation-timing'],
    }

    monitoring::check_prometheus { 'webperf-navtiming-error-rate':
        description     => 'high navtiming exception rate',
        query           => 'rate(webperf_errors[5m])', # Python exceptions per second
        method          => 'gt',
        warning         => 0.1, # 0 is normal
        critical        => 1,
        prometheus_url  => "http://prometheus.svc.${::site}.wmnet/ops",
        contact_group   => 'team-performance',
        dashboard_links => ['https://grafana.wikimedia.org/d/000000143/navigation-timing'],
    }

    monitoring::check_prometheus { 'webperf-navtiming-invalid-message-rate':
        description     => 'high navtiming invalid event rate',
        query           => 'sum(rate(webperf_navtiming_invalid_events[5m]))', # discards per second, across all groups
        method          => 'gt',
        warning         => 1, # ~0.2-0.5 is normal
        critical        => 5,
        prometheus_url  => "http://prometheus.svc.${::site}.wmnet/ops",
        contact_group   => 'team-performance',
        dashboard_links => ['https://grafana.wikimedia.org/d/000000143/navigation-timing'],
    }

    # Make a valid target for coal, and set up what's needed for the consumer
    # Consumes from the jumbo-eqiad cluster, just like navtiming
    class { '::coal::processor':
        kafka_brokers => $kafka_brokers,
        graphite_host => $graphite_host,
    }
}
