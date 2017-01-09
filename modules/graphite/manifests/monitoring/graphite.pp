# == Class: graphite::monitoring::graphite
#
# Monitor a graphite stack for important vitals, namely what it is interesting
# if we are losing data and how much.
# To that end, both "carbon-relay" (what accepts metrics from the outside) and
# "carbon-cache" (what read/writes datapoints from/to disk) are monitored, e.g.
# if there is any dropping of datapoints in their queues or errors otherwise.

class graphite::monitoring::graphite {
    # is carbon-relay queue full? (i.e. dropping data)
    monitoring::graphite_threshold { 'carbon-relay_queue_full':
        description     => 'carbon-relay queue full',
        metric          => 'sumSeries(transformNull(carbon.relays.graphite1001-*.destinations.*.fullQueueDrops))',
        from            => '10minutes',
        warning         => 200,
        critical        => 1000,
        nagios_critical => false,
    }

    # is carbon-cache able to write to disk (e.g. permissions)
    monitoring::graphite_threshold { 'carbon-cache_write_error':
        description     => 'carbon-cache write error',
        metric          => 'secondYAxis(sumSeries(carbon.agents.graphite1001-*.errors))',
        from            => '10minutes',
        warning         => 1,
        critical        => 8,
        nagios_critical => false,
    }

    # are carbon-cache queues overflowing their capacity?
    monitoring::graphite_threshold { 'carbon-cache_overflow':
        description     => 'carbon-cache queues overflow',
        metric          => 'secondYAxis(sumSeries(carbon.agents.graphite1001-*.cache.overflow))',
        from            => '10minutes',
        warning         => 1,
        critical        => 8,
        nagios_critical => false,
    }

    # are we creating too many metrics?
    monitoring::graphite_threshold { 'carbon-cache_many_creates':
        description     => 'carbon-cache too many creates',
        metric          => 'sumSeries(carbon.agents.graphite1001-*.creates)',
        from            => '1hour',
        warning         => 500,
        critical        => 1000,
        nagios_critical => false,
    }
}
