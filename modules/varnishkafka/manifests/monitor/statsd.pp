# === Define varnishkafka::monitor::statsd
#
# Configures Logster to parse Varnishkafka stats JSON files, extract metrics
# and push them to statsd.
#
define varnishkafka::monitor::statsd(
    $ensure                  = 'present',
    $log_statistics_file     = "/var/cache/varnishkafka/${name}.stats.json",
    $graphite_metric_prefix  = 'varnishkafka.stats',
    $statsd_host_port        = 'localhost:8125',
) {
    require ::varnishkafka

    Varnishkafka::Instance[$name] -> Varnishkafka::Monitor::Statsd[$name]

    # Send varnishkafka stats to statsd -> graphite using Logster.
    # Logster runs every minute using a cronjob.
    logster::job { "varnishkafka-${name}":
        ensure          => $ensure,
        minute          => '*/1',
        parser          => 'JsonLogster',
        logfile         => $log_statistics_file,
        logster_options => "-o statsd --statsd-host=${statsd_host_port} --metric-prefix=${graphite_metric_prefix}",
    }
}
