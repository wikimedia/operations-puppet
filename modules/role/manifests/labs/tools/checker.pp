class role::labs::tools::checker {
    include toollabs::checker

    system::role { 'role::labs::tools::checker':
        description => 'Exposes end points for external monitoring of internal systems',
    }
}
