class role::wmcs::toolforge::prometheus {
    system::role { $name: }

    include ::profile::toolforge::base
    include ::profile::toolforge::prometheus
}
