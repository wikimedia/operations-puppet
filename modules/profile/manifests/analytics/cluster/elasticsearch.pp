# Supports CirrusSearch usage on the analytics cluster
class profile::analytics::cluster::elasticsearch {
    # wikimedia/discovery/analytics will be deployed to this node
    scap::target { 'wikimedia/discovery/analytics':
        deploy_user => 'deploy-service',
    }
}
