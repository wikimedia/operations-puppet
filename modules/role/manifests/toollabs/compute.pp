# filtertags: labs-project-tools
class role::toollabs::compute {
    include ::toollabs::compute

    system::role { 'toollabs::compute': description => 'Toolforge compute node' }
}
