class role::toollabs::shadow {
    system::role { 'role::toollabs::shadow': description => 'Tool Labs gridengine shadow (backup) master' }

    class { '::toollabs::shadow':
        gridmaster => $role::toollabs::common::gridmaster,
    }
}
