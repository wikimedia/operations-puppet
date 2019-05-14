# == Class profile::local_dev::docker_publish
#
# Apparatus for publishing dev-images Docker images for local-charts.
#
# == Parameters
#
# [*registry*]
#   URI of a docker registry.
#
# [*username*]
#   User with rights to push to that registry.
#
# [*password*]
#   Password for user provided by private puppet.
#
# [*http_proxy*]
#   HTTP proxy (if needed).
#
class profile::local_dev::docker_publish(
    $registry = hiera('docker::registry'),
    $username = hiera('docker::registry::username'),
    $password = hiera('docker::registry::password'),
    $http_proxy = hiera('http_proxy', undef),
) {
    git::clone { 'releng/dev-images':
        directory => '/srv/dev-images',
        owner     => 'root',
        group     => 'wikidev',
        mode      => '0775',
        umask     => '002',
        origin    => 'https://gerrit.wikimedia.org/r/releng/dev-images.git',
    }

    file { '/etc/docker-pkg/dev-images.yaml':
        ensure  => present,
        content => template('profile/local_dev/docker-pkg-dev-images.yaml.erb'),
        owner   => 'root',
        group   => 'contint-admins',
        mode    => '0440'
    }
}
