class swift::monitoring::graphite_alerts {
    monitoring::graphite_threshold { "swift_${title}_dispersion_object":
        description     => "swift ${title} object availability",
        metric          => "keepLastValue(swift.${title}.dispersion.object.pct_found)",
        from            => '1hours',
        warning         => 95,
        critical        => 90,
        under           => true,
        nagios_critical => false,
    }

    monitoring::graphite_threshold { "swift_${title}_dispersion_container}":
        description     => "swift ${title} container availability",
        metric          => "keepLastValue(swift.${title}.dispersion.container.pct_found)",
        from            => '30min',
        warning         => 92,
        critical        => 88,
        under           => true,
        nagios_critical => false,
    }
}
