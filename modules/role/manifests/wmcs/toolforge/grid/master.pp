class role::wmcs::toolforge::grid::master {
    system::role { 'wmcs::toolforge::grid::master': description => 'Toolforge gridengine master' }

    include profile::toolforge::grid::base
    include profile::toolforge::grid::master
}
