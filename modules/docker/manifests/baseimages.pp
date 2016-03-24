# Classs: docker::baseimages
#
# Helper class that builds standard base images
class docker::baseimages {

    require ::docker::engine

    require_package('python-bootstrap-vz')

    $base_path = '/srv/images/base'
    file { '/srv/images':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { '/srv/images/base/':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        require => File['/srv/images'],
    }

    file { '/srv/images/base/jessie.yaml':
        source => 'puppet:///modules/docker/images/jessie.yaml',
        owner  => 'root',
        group  => 'root',
        mode   => '0544',
    }
}
