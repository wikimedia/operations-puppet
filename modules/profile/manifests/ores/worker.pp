class profile::ores::worker (
    Integer $celery_version = lookup('profile::ores::worker::celery_version', {'default_value' => 4 }),
) {
    # NOTE: The following is an include to avoid duplicate declaration issues
    # when both profile::ores::worker and profile::ores::web are included in the
    # same role class. scap::target also ends up using it
    include ::git::lfs # lint:ignore:wmf_styleguide
    class { '::ores::worker':
        celery_version => $celery_version,
    }
    class { '::profile::prometheus::statsd_exporter':
        relay_address => ''
    }
}
