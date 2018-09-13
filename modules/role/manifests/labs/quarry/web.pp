# filtertags: labs-project-quarry
class role::labs::quarry::web {
    require ::profile::labs::lvm::srv
    include ::profile::quarry::web
}
