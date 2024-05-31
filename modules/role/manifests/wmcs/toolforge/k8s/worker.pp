class role::wmcs::toolforge::k8s::worker {
    include profile::toolforge::base
    include profile::toolforge::infrastructure
    include profile::toolforge::k8s::worker
}
