# filtertags: labs-project-quarry
class role::labs::quarry::celeryrunner {
    require ::profile::labs::lvm::srv
    include ::labs_debrepo

    class { '::quarry::celeryrunner':
        require => [Class['::labs_debrepo']],
    }
}
