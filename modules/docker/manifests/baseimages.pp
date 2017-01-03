# Classs: docker::baseimages
#
# Helper class that builds standard base images
#
# === Parameters
#
# [*docker_registry]
#  The url of the docker registry where images should be uploaded
#
# [*proxy_address*]
#  The address of the proxy for downloading packages. Undefined by default
#
# [*proxy_port*]
#  The port of said proxy, if present. Undefined by default.
#
# [*distributions*]
#  List of distributions to build. Defaults to both jessie and trusty.
class docker::baseimages(
    $docker_registry,
    $proxy_address=undef,
    $proxy_port=undef,
    $distributions=['jessie', 'trusty'],
) {
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
        require => File['/srv/images/base'],
    }

    if 'alpine' in $distributions {
        if $proxy_address {
            $env = ["https_proxy=http://${proxy_address}:${proxy_port}"]
        }
        else {
            $env = undef
        }

        exec { 'git clone alpine linux':
            command     => '/usr/bin/git clone https://github.com/gliderlabs/docker-alpine.git alpine',
            creates     => '/srv/images/alpine',
            cwd         => '/srv/images',
            environment => $env,
            require     => File['/srv/images'],
        }
    }

    file { '/usr/local/bin/build-base-images':
        content => template('docker/images/build-base-images.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0544',
    }
}
