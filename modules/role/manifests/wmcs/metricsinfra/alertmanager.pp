class role::wmcs::metricsinfra::alertmanager {
    system::role { $name:
        description => 'CloudVPS monitoring infrastructure alert sender'
    }

    include ::profile::wmcs::metricsinfra::alertmanager
}
