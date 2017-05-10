# == Class role::restbase::dev_cluster
#
# Configures the restbase dev cluster
class role::restbase::production {
    # Just includes base, no LVS etc.
    include ::role::restbase::base
    include ::role::lvs::realserver
    system::role { 'restbase': description => 'Restbase (production)' }
}
