# filtertags: labs-project-tools
class role::toollabs::master {
    include ::toollabs::master

    system::role { 'toollabs::master': description => 'Toolforge gridengine master' }
}
