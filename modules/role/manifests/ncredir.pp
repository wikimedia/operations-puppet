class role::ncredir {
    system::role { 'ncredir': description => 'Non canonical domains redirection service' }
    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::ncredir
}
