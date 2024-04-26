class role::lvs::balancer {
    include profile::base::production

    include profile::pybal
    include profile::lvs
    include profile::base::no_firewall
}
