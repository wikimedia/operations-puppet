class role::toolforge::grid::master {
    system::role { 'toolforge::grid::master': description => 'Toolforge gridengine master' }

    include profile::toolforge::grid::base
    include profile::toolforge::grid::master
}
