class profile::ores::worker {
    # NOTE: The following is an include to avoid duplicate declaration issues
    # when both profile::ores::worker and profile::ores::web are included in the
    # same role class. scap::target also ends up using it
    include ::git::lfs # lint:ignore:wmf_styleguide
    class { '::ores::worker': }
    class { '::profile::prometheus::statsd_exporter': }
}
