# filtertags: labs-project-quarry
class role::labs::quarry::database {
    require ::profile::labs::lvm::srv

    include ::profile::quarry::database
}
