class swift_new::monitoring::graphite {
    monitoring::graphite_threshold { "swift_${name}_dispersion_object":
        description     => "swift ${name} object availability",
        metric          => "keepLastValue(swift.${name}.dispersion.object.pct_found)",
        from            => '1hours',
        warning         => 95,
        critical        => 90,
        under           => true,
        nagios_critical => false,
    }

    monitoring::graphite_threshold { "swift_${name}_dispersion_container":
        description     => "swift ${name} container availability",
        metric          => "keepLastValue(swift.${name}.dispersion.container.pct_found)",
        from            => '30min',
        warning         => 92,
        critical        => 88,
        under           => true,
        nagios_critical => false,
    }
}
