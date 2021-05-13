class role::wmcs::toolforge::redis_sentinel {
    system::role { $name:
        description => 'Toolforge Redis with automatic failover'
    }

    include ::profile::toolforge::base
    include ::profile::toolforge::redis_sentinel
    include ::profile::toolforge::infrastructure
    include ::profile::base::firewall
}
