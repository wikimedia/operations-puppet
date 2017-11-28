# == Class role::restbase::dev_cluster
#
# Configures the restbase dev cluster
# filtertags: labs-project-deployment-prep
class role::restbase::dev_cluster {
    # Just includes base, no LVS etc.
    include ::role::restbase::base
    system::role { 'restbase': description => "Restbase-dev (${::realm})" }
}
