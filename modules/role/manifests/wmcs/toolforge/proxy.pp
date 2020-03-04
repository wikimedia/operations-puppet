class role::wmcs::toolforge::proxy {
    system::role { $name: }

    include ::profile::toolforge::base
    include ::profile::toolforge::infrastructure
    include ::profile::toolforge::proxy
    include ::profile::toolforge::toolviews
    include ::profile::base::firewall
    include ::profile::toolforge::ferm_handlers
    include ::profile::toolforge::prometheus_fixup
}
