class role::thanos::backend {
    system::role { 'thanos::backend':
        description => 'Thanos (Prometheus long-term storage) backend',
    }

    include ::profile::standard
    include ::profile::base::firewall

    include ::profile::thanos::swift::backend
}
