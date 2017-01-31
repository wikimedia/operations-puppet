# Helper class to setup building toollabs related images

class toollabs::images {
    class { '::docker::baseimages':
        docker_registry => hiera('docker::registry'),
    }

    git::clone { 'operations/docker-images/toollabs-images':
        ensure    => present,
        directory => '/srv/images/toollabs',
    }
}
