# == Class role::restbase::production_new
#
# Configures the production cluster (new)
class role::restbase::production_new {
    include ::role::restbase::base
    include ::role::lvs::realserver
    system::role { 'restbase': description => 'Restbase (production, new)' }
}
