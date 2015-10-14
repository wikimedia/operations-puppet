class role::spare {
    include standard

    system::role { 'role::spare': description => 'Unused spare system' }
}
