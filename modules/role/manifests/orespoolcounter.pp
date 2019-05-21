# filtertags: labs-project-deployment-prep
class role::orespoolcounter {
    include ::profile::standard
    include ::profile::poolcounter
    include ::profile::base::firewall
    include ::profile::base::firewall::log

    system::role { 'orespoolcounter':
        description => 'ORES PoolCounter server',
    }
}
