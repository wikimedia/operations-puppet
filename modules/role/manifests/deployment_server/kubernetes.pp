# Deployment Server - including kubernetes stuff.
class role::deployment_server::kubernetes {

    system::role { 'deployment_server::kubernetes':
        description => 'Deployment server for all wikimedia services',
    }
    include role::deployment_server
    # Kubernetes deployments
    include profile::kubernetes::deployment_server
    include profile::kubernetes::deployment_server::helmfile
    include profile::kubernetes::deployment_server::mediawiki
    include profile::imagecatalog
    include profile::docker::engine
    include profile::docker::firewall
}
