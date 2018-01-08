class role::prometheus {
    system::role { 'prometheus::server':  }
    include ::role::prometheus::ops
    include ::role::prometheus::global
    include ::role::prometheus::services
    include ::role::prometheus::analytics
    include ::role::prometheus::k8s

    include ::standard
    # TODO: use role::lvs::realserver instead
    include ::lvs::realserver

    interface::add_ip6_mapped { 'main': }
}
