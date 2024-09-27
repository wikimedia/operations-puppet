class role::dragonfly::supernode {
    include profile::base::production
    include profile::firewall

    include profile::dragonfly::supernode
}
