class role::lvs::balancer {
    system::role { 'lvs::balancer': description => 'LVS balancer' }

    include ::lvs::configuration
    include ::standard

    include ::profile::pybal
    include ::profile::lvs

}
