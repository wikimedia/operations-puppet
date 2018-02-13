# Define various checks for Maps
class profile::maps::alerts {
    monitoring::graphite_threshold { 'tilerator-tile-generation':
        description     => 'Maps tiles generation',
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/maps-performances?panelId=8&fullscreen&orgId=1'],
        metric          => 'transformNull(sumSeries(tilerator.gen.*.*.*.done.sample_rate),0)',
        # Tilerator should be generating tiles at least 2 hours per day
        # Values need to be adjusted if synchronization frequency is changed
        under           => true,
        warning         => 10,
        critical        => 5,
        from            => '1day',
        percentage      => 90,
    }
}
