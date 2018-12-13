class profile::ores::worker {
    include ::ores::worker
    class { '::profile::prometheus::statsd_exporter': }
}
