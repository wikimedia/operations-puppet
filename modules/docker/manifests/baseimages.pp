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
#  List of distributions to build. Defaults to stretch
class docker::baseimages(
    Stdlib::Host $docker_registry,
    Optional[Stdlib::Host] $proxy_address = undef,
    Optional[Stdlib::Port] $proxy_port = undef,
    Array[String] $distributions = ['stretch'],
) {
    # We need docker running
    Service[docker] -> Class[docker::baseimages]

    ensure_packages(['bootstrap-vz'])

    file { '/srv/images':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { '/srv/images/base':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    ## Stretch
    $stretch_keyring = '/srv/images/base/wikimedia-stretch.pub.gpg'
    file { '/srv/images/base/stretch.yaml':
        content => template('docker/images/stretch.yaml.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0544',
    }

    file { $stretch_keyring:
        ensure => present,
        source => 'puppet:///modules/docker/wikimedia-stretch.pub.gpg',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }
    ## end stretch

    # Buster
    $buster_keyring = '/srv/images/base/wikimedia-buster.pub.gpg'
    file { '/srv/images/base/buster.yaml':
        content => template('docker/images/buster.yaml.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0544',
    }

    file { $buster_keyring:
        ensure => present,
        source => 'puppet:///modules/docker/wikimedia-buster.pub.gpg',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }
    ## end buster

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

        file { '/usr/local/bin/build-alpine':
            content => template('docker/images/build-alpine.erb'),
            owner   => 'root',
            group   => 'root',
            mode    => '0544',
        }
    }

    file { '/usr/local/bin/build-base-images':
        content => template('docker/images/build-base-images.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0544',
    }

    # Cronjob to refresh the base images every week on sunday.
    systemd::timer::job { 'debian-weekly-rebuild':
        description         => 'Weekly job to rebuild the debian base images',
        command             => '/usr/local/bin/build-base-images',
        environment         => {'DISTRIBUTIONS' => 'stretch buster'},
        interval            => {'start' => 'OnCalendar', 'interval' => 'Sun *-*-* 04:00:00'},
        user                => 'root',
        max_runtime_seconds => 86400,
    }
}
