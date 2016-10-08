class role::toollabs::compute {
    include ::toollabs::compute

    system::role { 'role::toollabs::compute': description => 'Tool Labs compute node' }
}
