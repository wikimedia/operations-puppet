# filtertags: labs-project-tools
class role::toollabs::shadow {
    system::role { 'toollabs::shadow': description => 'Toolforge gridengine shadow (backup) master' }

    class { '::toollabs::shadow':
        gridmaster => $role::toollabs::common::gridmaster,
    }
}
