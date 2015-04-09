class swift_new::monitoring::graphite (
    $swift_cluster = $::swift_new::params::swift_cluster,
) {
    monitoring::graphite_threshold { "swift_${swift_cluster}_dispersion_object":
        description     => "swift ${swift_cluster} object availability",
        metric          => "swift.${swift_cluster}.dispersion.object.pct_found",
        from            => '1hours',
        warning         => 95,
        critical        => 90,
        under           => true,
        nagios_critical => false,
    }

    monitoring::graphite_threshold { "swift_${swift_cluster_dispersion_container}":
        description     => "swift ${swift_cluster} container availability",
        metric          => "swift.${swift_cluster}.dispersion.container.pct_found",
        from            => '30min',
        warning         => 92,
        critical        => 88,
        under           => true,
        nagios_critical => false,
    }
}
