# == Class role::restbase::test_cluster
#
# Configures the restbase test cluster
class role::restbase::test_cluster {
    # Just includes base, no LVS etc.
    include ::role::restbase::base
    system::role { 'restbase': description => "Restbase-test (${::realm})" }
}
