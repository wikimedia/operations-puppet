# == Class role::restbase::production_new
#
# Configures the production cluster (new)
class role::restbase::production_new {
    include ::passwords::cassandra
    include ::base::firewall
    include ::standard
    include ::profile::cassandra
    system::role { 'restbase': description => 'Restbase (Cassandra 3.x-only)' }
}
