class role::spare {
    include standard
    include base::firewall

    system::role { 'role::spare': description => 'Unused spare system' }
}
