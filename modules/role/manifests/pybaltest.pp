class role::pybaltest {
    system::role { 'pybaltest':
        description => 'pybal testing/development'
    }

    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::pybaltest
    include ::profile::conftool::master
}
