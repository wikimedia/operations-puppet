class role::toollabs::static {
    include ::toollabs::static

    system::role { 'role::toollabs::static':
        description => 'Tool Labs static http server',
    }
}
