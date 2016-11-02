# Classs: docker::baseimages
#
# Helper class that builds standard base images
class docker::baseimages($docker_registry) {
    # We need docker running
    Service[docker] -> Class[docker::baseimages]

    require_package('python-bootstrap-vz')
    require_package('debootstrap')

    file { '/srv/images':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { '/srv/images/base':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        require => File['/srv/images'],
    }

    file { '/srv/images/base/jessie.yaml':
        content => template('docker/images/jessie.yaml.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0544',
        require => File['/srv/images/base']
    }

    file { '/usr/local/bin/build-base-images':
        content => template('docker/images/build-base-images.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0544',
    }
}
