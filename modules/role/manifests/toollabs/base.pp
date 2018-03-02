class role::toollabs::base {
    include ::toollabs::base

    system::role { 'toollabs::base':
        description => 'This server is part of the Toolforge cluster'
    }
}
