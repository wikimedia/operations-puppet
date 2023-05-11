class role::poolcounter::server {
    include ::profile::base::production
    include ::profile::poolcounter
    include ::profile::firewall

    system::role { 'poolcounter':
        description => 'PoolCounter server',
    }
}
