class role::wmcs::toolforge::k8s::node {
    system::role { $name: }

    include ::profile::base::firewall
    include ::profile::toolforge::base
    include ::profile::toolforge::infrastructure
    include ::profile::toolforge::k8s::node
    # TODO: what to do with this one?
    #include ::toollabs::ferm_handlers
}
