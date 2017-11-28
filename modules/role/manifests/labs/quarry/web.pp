# filtertags: labs-project-quarry
class role::labs::quarry::web {
    require ::profile::labs::lvm::srv
    include ::labs_debrepo

    class { '::quarry::web':
        require => [Class['::labs_debrepo']],
    }
}
