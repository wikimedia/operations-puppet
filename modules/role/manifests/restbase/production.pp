# == Class role::restbase::production
#
# Configures the production cluster
class role::restbase::production {
    include ::role::restbase::base
    include ::role::lvs::realserver
    system::role { 'restbase': description => 'Restbase (production with Cassandra 3.x)' }
}
