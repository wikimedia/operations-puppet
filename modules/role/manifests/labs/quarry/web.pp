# filtertags: labs-project-quarry
class role::labs::quarry::web {
    include role::labs::lvm::srv
    include ::labs_debrepo

    class { '::quarry::web':
        require => [Mount['/srv'], Class['::labs_debrepo']],
    }
}
