class role::orespoolcounter {
    include ::profile::base::production
    include ::profile::poolcounter
    include ::profile::firewall

    system::role { 'orespoolcounter':
        description => 'ORES PoolCounter server',
    }
}
