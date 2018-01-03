# == Class role::restbase::production_ng
#
# Configures the production cluster (next-gen)
class role::restbase::production_ng {
    include ::role::restbase::base
    include ::role::lvs::realserver
    system::role { 'restbase': description => 'Restbase (production with Cassandra 3.x)' }
}
