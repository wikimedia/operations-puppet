class role::labs::tools::static {
    include toollabs::static

    system::role { 'role::labs::tools::static':
        description => 'Tool Labs static http server',
    }
}
