# filtertags: labs-project-quarry
class role::labs::quarry::celeryrunner {
    include role::labs::lvm::srv
    include ::labs_debrepo

    class { '::quarry::celeryrunner':
        require => [Mount['/srv'], Class['::labs_debrepo']],
    }
}
