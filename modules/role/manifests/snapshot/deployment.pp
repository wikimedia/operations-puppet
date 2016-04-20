# Defines snapshot data dump deployment target(s)
class role::snapshot::deployment {
    scap::target { 'dumps/dumps':
        deploy_user => 'datasets',
        key_name    => 'dumps',
        manage_user => false,
    }
}
