# filtertags: labs-project-deployment-prep
class role::orespoolcounter {
    include ::standard
    include ::profile::poolcounter
    include ::profile::base::firewall

    system::role { 'orespoolcounter':
        description => 'ORES PoolCounter server',
    }
}
