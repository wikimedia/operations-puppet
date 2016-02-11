class role::labs::tools::redis {
    system::role {
        'role::labs::tools::redis':
        description => 'Server that hosts shared Redis instance'
    }

    include toollabs::redis
}
