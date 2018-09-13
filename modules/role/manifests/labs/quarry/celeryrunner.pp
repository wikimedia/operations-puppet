# filtertags: labs-project-quarry
class role::labs::quarry::celeryrunner {
    require ::profile::labs::lvm::srv
    include ::profile::quarry::celeryrunner
}
