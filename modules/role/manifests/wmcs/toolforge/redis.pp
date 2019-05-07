class role::wmcs::toolforge::redis {
    system::role { $name: }

    include ::profile::toolforge::base
    include ::profile::toolforge::redis
    include ::profile::toolforge::infrastructure
}
