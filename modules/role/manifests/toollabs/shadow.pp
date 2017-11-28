# filtertags: labs-project-tools
class role::toollabs::shadow {
    system::role { 'toollabs::shadow': description => 'Tool Labs gridengine shadow (backup) master' }

    class { '::toollabs::shadow':
        gridmaster => $role::toollabs::common::gridmaster,
    }
}
