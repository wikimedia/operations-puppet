class role::ncredir {
    system::role { 'ncredir': description => 'Non canonical domains redirection service' }
    include ::profile::standard
    include ::profile::base::firewall
    # TODO: use ::role::lvs::realserver instead
    include ::lvs::realserver  # lint:ignore:wmf_styleguide
    include ::profile::ncredir
}
