class role::ncredir {
    include profile::base::production
    include profile::firewall
    include profile::lvs::realserver
    include profile::lvs::realserver::ipip
    include profile::nginx
    include profile::ncredir
}
