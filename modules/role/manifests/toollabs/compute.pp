# filtertags: labs-project-tools
class role::toollabs::compute {
    include ::toollabs::compute

    system::role { 'toollabs::compute': description => 'Tool Labs compute node' }
}
