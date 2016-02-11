class role::labs::tools::compute {
    include toollabs::compute

    system::role { 'role::labs::tools::compute': description => 'Tool Labs compute node' }
}
