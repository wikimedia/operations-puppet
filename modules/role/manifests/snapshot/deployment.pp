# Defines snapshot data dump deployment target(s)
class role::snapshot::deployment {
    scap::target { 'dumps/dumps':
        deploy_user => 'datasets',
        manage_user => false,
        key_name    => 'dumpsdeploy',
    }
}
