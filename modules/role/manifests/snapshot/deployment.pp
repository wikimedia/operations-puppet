class role::snapshot::deployment {
    scap::target { 'dumps/dumps':
        deploy_user       => 'datasets',
        public_key_source => 'puppet:///modules/snapshots/deployment/dumpsdeploy_rsa.pub',
        manage_user       => false,
    }
}
