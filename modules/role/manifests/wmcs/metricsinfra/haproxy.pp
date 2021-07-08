class role::wmcs::metricsinfra::haproxy {
    system::role { $name: }

    include ::profile::wmcs::metricsinfra::haproxy
}
