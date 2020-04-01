class role::thanos::query {
    system::role { 'thanos::query':
        description => 'Thanos querier service',
    }

    include ::profile::standard
    include ::profile::base::firewall

    include ::profile::thanos::query
}
