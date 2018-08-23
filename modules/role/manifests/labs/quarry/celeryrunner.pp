# filtertags: labs-project-quarry
class role::labs::quarry::celeryrunner {
    require ::profile::labs::lvm::srv
    require ::labs_debrepo
    include ::profile::quarry::celeryrunner
}
