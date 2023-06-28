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
        settings => {
            'safe' => {
                'directory' => '/srv/dev-images',
            }
        }
    }

    git::clone { 'releng/dev-images':
        directory => '/srv/dev-images',
        owner     => 'root',
        group     => 'wikidev',
        mode      => '0775',
        umask     => '002',
        origin    => 'https://gitlab.wikimedia.org/releng/dev-images.git',
        require   => Git::Systemconfig['safe.directory-srv-dev-images']
    }

    file { '/etc/docker-pkg/dev-images.yaml':
        ensure  => present,
        content => template('profile/local_dev/docker-pkg-dev-images.yaml.erb'),
        owner   => 'root',
        group   => 'contint-admins',
        mode    => '0440'
    }
}
