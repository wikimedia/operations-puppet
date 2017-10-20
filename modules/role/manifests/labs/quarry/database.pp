# filtertags: labs-project-quarry
class role::labs::quarry::database {
    require ::profile::labs::lvm::srv

    class { '::quarry::database':
    }
}
