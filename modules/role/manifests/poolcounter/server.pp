# filtertags: labs-project-deployment-prep
class role::poolcounter::server {
    include ::profile::base::production
    include ::profile::poolcounter
    include ::profile::base::firewall

    system::role { 'poolcounter':
        description => 'PoolCounter server',
    }
}
