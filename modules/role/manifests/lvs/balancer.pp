class role::lvs::balancer {
    system::role { 'role::lvs::balancer': description => 'LVS balancer' }

    include ::lvs::configuration
    include ::standard

    include ::profile::pybal
    include ::profile::lvs

    if $::site in ['eqiad', 'codfw'] {
        include ::lvs::balancer::runcommand
    }

}
