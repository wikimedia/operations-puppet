class role::wmcs::prometheus {
    system::role { $name: }

    include ::profile::toolforge::prometheus
}
