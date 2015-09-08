define swift::monitoring::graphite_alerts (
    $cluster = $title,
) {
    monitoring::graphite_threshold { "swift_${cluster}_dispersion_object":
        description     => "swift ${cluster} object availability",
        metric          => "keepLastValue(swift.${cluster}.dispersion.object.pct_found)",
        from            => '1hours',
        warning         => 95,
        critical        => 90,
        under           => true,
        nagios_critical => false,
    }

    monitoring::graphite_threshold { "swift_${cluster}_dispersion_container}":
        description     => "swift ${cluster} container availability",
        metric          => "keepLastValue(swift.${cluster}.dispersion.container.pct_found)",
        from            => '30min',
        warning         => 92,
        critical        => 88,
        under           => true,
        nagios_critical => false,
    }
}
