# == Class role::restbase::production
#
# Configures the production cluster
class role::restbase::production {
    include ::role::restbase::base
    include ::profile::lvs::realserver
    system::role { 'restbase': description => 'Restbase (production with Cassandra 3.x)' }
}
