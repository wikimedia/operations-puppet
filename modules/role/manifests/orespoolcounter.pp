# filtertags: labs-project-deployment-prep
class role::orespoolcounter {
    include ::profile::base::production
    include ::profile::poolcounter
    include ::profile::base::firewall

    system::role { 'orespoolcounter':
        description => 'ORES PoolCounter server',
    }
}
