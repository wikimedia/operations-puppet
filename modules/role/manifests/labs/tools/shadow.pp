class role::labs::tools::shadow {
    system::role { 'role::labs::tools::shadow': description => 'Tool Labs gridengine shadow (backup) master' }

    class { 'toollabs::shadow':
        gridmaster => $role::labs::tools::common::gridmaster,
    }
}
