# == Class role::restbase::dev_cluster
#
# Configures the restbase dev cluster
class role::restbase::dev_cluster {
    # Just includes base, no LVS etc.
    include ::role::restbase::base
    system::role { 'restbase': description => "Restbase-dev (${::realm})" }
}
