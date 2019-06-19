# filtertags: labs-project-deployment-prep
class role::orespoolcounter {
    include ::profile::standard
    include ::profile::poolcounter
    include ::profile::base::firewall

    system::role { 'orespoolcounter':
        description => 'ORES PoolCounter server',
    }
}
