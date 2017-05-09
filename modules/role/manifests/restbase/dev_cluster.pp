# == Class role::restbase::dev_cluster
#
# Configures the restbase dev cluster
class role::restbase::dev_cluster {
    include ::passwords::cassandra
    include ::base::firewall
    include ::standard

    include ::profile::cassandra
    include ::profile::restbase

    # TODO: create a base role for deployment-prep
    if hiera('has_lvs', true) {
        include ::role::lvs::realserver
    }

    system::role { 'restbase': description => "Restbase-dev (${::realm})" }
}
