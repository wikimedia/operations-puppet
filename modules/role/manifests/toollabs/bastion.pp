# filtertags: labs-project-tools
class role::toollabs::bastion {

    include ::toollabs::base
    include ::toollabs::bastion

    system::role { 'toollabs::bastion': description => 'Toolforge bastion' }
}
