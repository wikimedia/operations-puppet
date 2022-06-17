class role::wmcs::metricsinfra::prometheus {
    system::role { $name:
        description => 'CloudVPS monitoring infrastructure Prometheus server'
    }

    include ::profile::wmcs::metricsinfra::prometheus
    include ::profile::wmcs::metricsinfra::prometheus_configurator
}
