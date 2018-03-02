class role::toollabs::base {
    include ::toollabs::base

    system::role { 'toollabs::base':
        description => 'server part of the Toolforge cluster'
    }
}
