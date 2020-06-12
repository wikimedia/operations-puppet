class role::wmcs::paws::k8s::haproxy {
    system::role { $name: }

    include ::profile::wmcs::paws::common
    include ::profile::wmcs::paws::haproxy
}
