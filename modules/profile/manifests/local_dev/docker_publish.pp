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
    Stdlib::Host $registry = lookup('docker::registry'),
    String $password = lookup('profile::local_dev::ci_build_user_password'),
    Optional[Stdlib::Httpurl] $http_proxy = lookup('http_proxy', {'default_value' => undef})
){

    git::systemconfig { 'safe.directory-srv-dev-images':
        ensure => absent,
    }

    # The sudo rule granted in modules/admin/data/data.yaml
    $builder_user = 'dockerpkg-builder'
    $builder_group = 'contint-admins'

    user { $builder_user:
        ensure => present,
        gid    => $builder_group,
        system => true,
        home   => '/nonexistent',
        shell  => '/usr/sbin/nologin',
    }

    git::clone { 'releng/dev-images':
        directory => '/srv/dev-images',
        owner     => $builder_user,
        group     => $builder_group,
        origin    => 'https://gitlab.wikimedia.org/releng/dev-images.git',
        require   => Git::Systemconfig['safe.directory-srv-dev-images'],
    }

    file { '/etc/docker-pkg/dev-images.yaml':
        ensure  => present,
        content => template('profile/local_dev/docker-pkg-dev-images.yaml.erb'),
        owner   => 'root',
        group   => $builder_group,
        mode    => '0440'
    }
}
