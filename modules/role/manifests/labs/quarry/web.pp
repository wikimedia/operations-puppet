# filtertags: labs-project-quarry
class role::labs::quarry::web {
    require ::profile::labs::lvm::srv
    require ::labs_debrepo

    class { '::quarry::base': }

    include ::profile::quarry::web
}
