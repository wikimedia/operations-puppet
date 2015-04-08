class role::hierator {
    system::role { 'role::hierator':
        description => 'Hierator server',
    }

    include ::hierator
}
