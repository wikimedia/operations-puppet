# Helper class to setup building toollabs related images
class toollabs::images {
    require ::docker::baseimages

    git::clone { 'operations/docker-images/toollabs-images':
        ensure    => present,
        directory => '/srv/images/toollabs',
    }
}