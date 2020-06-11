class role::wmcs::paws::k8s::control {
    system::role { $name: }

    include ::profile::wmcs::paws::common
    include ::profile::wmcs::paws::k8s::control
}
