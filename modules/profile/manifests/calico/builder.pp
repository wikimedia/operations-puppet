class profile::calico::builder {
    # Calico builder version
    $calico_version=hiera('profile::calico::builder::version')
    # Calico builder directory
    $directory=hiera('profile::calico::builder::directory')
    # Proxy url, if present
    $proxy_address=hiera('profile::calico::builder::proxy_address')
    $registry_address=hiera('docker::registry')
    $registry_user=hiera('docker::registry_user')

    # Needs docker to be installed and working
    require ::docker

    # Needed to build calicoctl
    apt::pin { 'go':
        package  => 'golang-go',
        pin      => 'release a=jessie-backports',
        priority => '1001',
        before   => Package['golang-go'],
    }

    package { 'golang-go':
        ensure => present,
    }

    require_package('build-essential', 'fakeroot')

    if $proxy_address {
        file_line { 'Docker proxy':
            ensure => present,
            path   => '/etc/default/docker',
            line   => "export http_proxy=${proxy_address}",
            match  => '^\#?export http_proxy=',
            notify => Service['docker'],
        }
    }


    # Glide is needed to build calicoctl
    # It is a go binary that is available on debian unstable
    file { '/usr/local/bin/glide':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        # lint:ignore:puppet_url_without_modules
        source => 'puppet:///volatile/misc/glide-binaries/glide',
        # lint:endignore
    }

    # User for the build needs to be part of the docker group,
    # as building depends on docker.
    user { 'calicobuild':
        ensure     => present,
        shell      => '/bin/bash',
        system     => true,
        managehome => true,
        groups     => 'docker',
    }

    git::clone{ 'operations/calico-containers':
        branch    => $calico_version,
        owner     => 'calicobuild',
        require   => User['calicobuild'],
        directory => "${directory}/calico-containers",
    }

    # Script to build the project and push it to our registry
    file { '/usr/local/bin/build-calico':
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        content => template('profile/calico/build-calico.sh.erb'),
    }
}
