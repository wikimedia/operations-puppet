class role::wmcs::toolforge::static {
    system::role { $name: }

    include ::profile::toolforge::base
    include ::profile::toolforge::static
    include ::profile::toolforge::infrastructure
}
