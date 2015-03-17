class graphite::monitoring::graphite {
    monitoring::graphite_threshold { 'carbon-relay queue full':
        description     => 'carbon-relay queue full',
        metric          => 'sumSeries(carbon.relays.graphite1001-*.destinations.*.fullQueueDrops)',
        from            => '10minutes',
        warning         => 200,
        critical        => 1000,
        nagios_critical => false
    }

    monitoring::graphite_threshold { 'carbon-cache write error':
        description     => 'carbon-cache write error',
        metric          => 'secondYAxis(sumSeries(carbon.agents.graphite1001-*.errors))',
        from            => '10minutes',
        warning         => 1,
        critical        => 8,
        nagios_critical => false
    }

    monitoring::graphite_threshold { 'carbon-cache overflows':
        description     => 'carbon-cache queues overflow',
        metric          => 'secondYAxis(sumSeries(carbon.agents.graphite1001-*.cache.overflow))',
        from            => '10minutes',
        warning         => 1,
        critical        => 8,
        nagios_critical => false
    }

    monitoring::graphite_threshold { 'carbon-cache creates':
        description     => 'carbon-cache too many creates',
        metric          => 'sumSeries(carbon.agents.graphite1001-*.creates)',
        from            => '1hour',
        warning         => 200,
        critical        => 1000,
        nagios_critical => false
    }
}
