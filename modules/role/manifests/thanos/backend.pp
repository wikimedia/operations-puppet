class role::thanos::backend {
    system::role { 'thanos::backend':
        description => 'Swift backend (Thanos cluster)',
    }

    include ::profile::base::production
    include ::profile::firewall

    include ::profile::thanos::swift::backend
}
