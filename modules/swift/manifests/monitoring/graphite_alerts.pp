define swift::monitoring::graphite_alerts (
    $cluster = $title,
) {
    monitoring::graphite_threshold { "swift_${cluster}_dispersion_object":
        description     => "swift ${cluster} object availability",
        dashboard_links => ["https://grafana.wikimedia.org/dashboard/file/swift?panelId=8&fullscreen&orgId=1&var-DC=${cluster}"],
        metric          => "keepLastValue(swift.${cluster}.dispersion.object.pct_found)",
        from            => '1hours',
        warning         => 95,
        critical        => 90,
        under           => true,
        nagios_critical => false,
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Swift/How_To',
    }

    monitoring::graphite_threshold { "swift_${cluster}_dispersion_container}":
        description     => "swift ${cluster} container availability",
        dashboard_links => ["https://grafana.wikimedia.org/dashboard/file/swift?panelId=8&fullscreen&orgId=1&var-DC=${cluster}"],
        metric          => "keepLastValue(swift.${cluster}.dispersion.container.pct_found)",
        from            => '30min',
        warning         => 92,
        critical        => 88,
        under           => true,
        nagios_critical => false,
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Swift/How_To',
    }

    monitoring::graphite_threshold { "mediawiki_${cluster}_media_uploads":
        description     => "mediawiki originals uploads (hourly) for ${cluster}",
        dashboard_links => ["https://grafana.wikimedia.org/dashboard/file/swift?panelId=9&fullscreen&orgId=1&var-DC=${cluster}"],
        metric          => "summarize(nonNegativeDerivative(keepLastValue(swift.${cluster}.containers.mw-media.originals.objects)), \"1h\")",
        from            => '5h',
        warning         => 2000,
        critical        => 3000,
        nagios_critical => false,
        percentage      => 80,
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Swift/How_To',
    }
}
