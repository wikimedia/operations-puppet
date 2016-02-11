class role::labs::tools::master {
    include toollabs::master

    system::role { 'role::labs::tools::master': description => 'Tool Labs gridengine master' }
}
