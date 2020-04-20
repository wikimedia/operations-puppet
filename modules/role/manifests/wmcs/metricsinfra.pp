class role::wmcs::metricsinfra {
    system::role { $name:
        description => 'CloudVPS Prometheus based instance monitoring'
    }

    include ::profile::labs::lvm::srv
    include ::profile::wmcs::prometheus::metricsinfra
}
