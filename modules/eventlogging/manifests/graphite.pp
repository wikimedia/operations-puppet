# Class defining icinga checks on graphite for eventlogging
# see nagios.pp for definition of these macros
class eventlogging::monitor::graphite() {

    # Checks if 1% of the data points sampled
    # exceeds the desired threshold
    # percentage can be changed by specifying 'percentage' parameter
    monitor_graphite_threshold {'eventlogging_throughput':
        description     => 'Throughput of event logging events',
        metric          => 'eventlogging.overall.raw.rate',
        warning         => 350,
        critical        => 500,
        from            => '15min', #Date from which to fetch data.
        nagios_critical => 'false',
        contact_group   => 'analytics'
    }
}