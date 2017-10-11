# == Class role::restbase::production_ng
#
# Configures the production cluster (next-gen)
class role::restbase::production_ng {
    include ::passwords::cassandra
    include ::profile::base::firewall
    include ::standard
    include ::profile::cassandra
    system::role { 'restbase': description => 'Restbase (Cassandra 3.x-only)' }
}
