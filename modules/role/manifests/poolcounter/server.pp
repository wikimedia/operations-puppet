# filtertags: labs-project-deployment-prep
class role::poolcounter::server {
    include ::profile::standard
    include ::profile::poolcounter
    include ::profile::base::firewall

    system::role { 'poolcounter':
        description => 'PoolCounter server',
    }
}
