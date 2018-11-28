class role::wmcs::toolforge::grid::shadow {
    system::role { 'wmcs::toolforge::grid::shadow': description => 'Toolforge gridengine shadow master' }

    include profile::toolforge::base
    include profile::toolforge::apt_pinning
    include profile::toolforge::grid::base
    include profile::toolforge::grid::shadow
}
