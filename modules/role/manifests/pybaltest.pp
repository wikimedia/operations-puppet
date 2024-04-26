class role::pybaltest {
    include profile::base::production
    include profile::firewall
    include profile::pybaltest
    include profile::conftool::master
}
