# == Class profile::analytics::asoranking
#
# Sets up the ASO ranking tool.
#
class profile::analytics::asoranking {
    scap::target { 'performance/asoranking':
        deploy_user => 'analytics',
        key_name    => 'analytics_deploy',
        manage_user => true,
    }
}
