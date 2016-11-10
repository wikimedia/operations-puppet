class profile::docker::builder(
    $proxy_address=undef,
    $proxy_port=undef,
){

    system::role { 'role::docker::builder':
        description => 'Docker images builder'
    }

    class { 'docker::baseimages':
        docker_registry => hiera('docker::registry'),
        proxy_address   => $proxy_address,
        proxy_port      => $proxy_port,
        distributions   => ['jessie'],
    }

    # TODO: create a repo for base images in prod for this
}
