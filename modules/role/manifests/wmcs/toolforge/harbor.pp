class role::wmcs::toolforge::harbor {
    system::role { $name: }

    include profile::toolforge::base
    include profile::toolforge::infrastructure
    include profile::toolforge::harbor
}
