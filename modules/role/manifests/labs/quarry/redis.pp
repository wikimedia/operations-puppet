# filtertags: labs-project-quarry
class role::labs::quarry::redis {
    require ::profile::labs::lvm::srv
    include ::profile::quarry::redis
}
