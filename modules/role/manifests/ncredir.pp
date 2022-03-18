class role::ncredir {
    system::role { 'ncredir': description => 'Non canonical domains redirection service' }
    include profile::base::production
    include profile::base::firewall
    include profile::lvs::realserver
    include profile::nginx
    include profile::ncredir
}
