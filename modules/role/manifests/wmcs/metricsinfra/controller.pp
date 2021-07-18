class role::wmcs::metricsinfra::controller {
    system::role { $name:
        description => 'CloudVPS monitoring infrastructure configuration management',
    }

    include ::profile::wmcs::metricsinfra::prometheus_manager
}
