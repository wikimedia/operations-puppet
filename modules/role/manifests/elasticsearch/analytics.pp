# Supports CirrusSearch usage on the analytics cluster
class role::elasticsearch::analytics {
    # wikimedia/discovery/analytics will be deployed to this node
    scap::target { 'wikimedia/discovery/analytics':
        deploy_user => 'deploy-service',
    }

    require_package('virtualenv', 'zip')
    scap::target { 'search/MjoLniR/deploy':
        deploy_user => 'deploy-service',
    }
}
