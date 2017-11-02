class profile::ci::shipyard(
    $registry = hiera('docker::registry'),
    $username = hiera('docker::registry::username'),
    $password = hiera('docker::registry::password'),
    $http_proxy = hiera('http_proxy', undef),
) {
    class { '::docker_pkg': }

    file { '/etc/docker-pkg/':
        ensure => directory,
        owner  => root,
        group  => root,
        mode   => '0755',
    }

    # TODO: make jenkins able to read this file as well?
    file { '/etc/docker-pkg/integration.yaml':
        ensure  => present,
        content => template('profile/ci/shipyard/docker-pkg-integration-config.yaml.erb'),
        owner   => 'root',
        group   => 'contint-admins',
        mode    => '0440'
    }
}
