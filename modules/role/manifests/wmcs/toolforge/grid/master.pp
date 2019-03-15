class role::wmcs::toolforge::grid::master {
    system::role { $name:
        description => 'Toolforge gridengine master'
    }

    include profile::toolforge::base
    include profile::toolforge::apt_pinning
    include profile::toolforge::grid::base
    include profile::toolforge::grid::master
    include profile::toolforge::grid::submit_host
}
