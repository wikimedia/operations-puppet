# filtertags: labs-project-tools
class role::toollabs::bastion {
    include ::toollabs::bastion

    system::role { 'role::toollabs::bastion': description => 'Tool Labs bastion' }
}
