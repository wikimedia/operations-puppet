class role::wmcs::toolforge::redis_sentinel {
    include profile::toolforge::base
    include profile::toolforge::redis_sentinel
    include profile::toolforge::infrastructure
    include profile::firewall
}
