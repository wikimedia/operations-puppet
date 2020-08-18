class profile::ci::shipyard(
    Stdlib::Fqdn $registry = hiera('docker::registry'),
    String $username = hiera('docker::registry::username'),
    String $password = hiera('docker::registry::password'),
    Variant[Stdlib::HTTPUrl, Stdlib::HTTPSUrl] $http_proxy = hiera('http_proxy', undef),
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
