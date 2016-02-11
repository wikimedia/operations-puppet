class role::labs::tools::bastion {
    include toollabs::bastion

    system::role { 'role::labs::tools::bastion': description => 'Tool Labs bastion' }
}
