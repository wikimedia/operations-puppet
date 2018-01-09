# == Class role::restbase::dev_cluster
#
# Configures the restbase dev cluster
class role::restbase::production {
    # Just includes base, no LVS etc.
    include ::passwords::cassandra
    include ::base::firewall
    include ::standard
    include ::profile::restbase
    include ::role::lvs::realserver
    system::role { 'restbase': description => 'Restbase (production, Cass 2.2.x)' }
}
