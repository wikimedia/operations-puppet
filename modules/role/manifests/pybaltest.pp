class role::pybaltest {
    system::role { 'pybaltest':
        description => 'pybal testing/development'
    }

    include ::profile::base::production
    include ::profile::base::firewall
    include ::profile::pybaltest
    include ::profile::conftool::master
}
