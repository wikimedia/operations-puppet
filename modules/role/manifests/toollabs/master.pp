# filtertags: labs-project-tools
class role::toollabs::master {
    include ::toollabs::master

    system::role { 'toollabs::master': description => 'Tool Labs gridengine master' }
}
