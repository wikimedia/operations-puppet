class profile::docker::builder {
    system::role { 'role::docker::builder':
        description => 'Docker images builder'
    }

    class { 'docker::baseimages':
        docker_registry => hiera('docker::registry')
    }

    # TODO: create a repo for base images in prod for this
}
