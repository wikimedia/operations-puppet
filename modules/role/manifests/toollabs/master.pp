# filtertags: labs-project-tools
class role::toollabs::master {
    include ::toollabs::master

    system::role { 'role::toollabs::master': description => 'Tool Labs gridengine master' }
}
