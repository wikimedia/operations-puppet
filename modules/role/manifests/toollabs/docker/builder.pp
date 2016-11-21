# filtertags: labs-project-tools
class role::toollabs::docker::builder {
    include ::toollabs::infrastructure

    class { '::docker::engine': }

    class { '::toollabs::images': }

    # This requires push privilages
    $docker_username = hiera('docker::username')
    $docker_password = hiera('docker::password')
    $docker_registry = hiera('docker::registry')

    # uses strict_encode64 since encode64 adds newlines?!
    $docker_auth = inline_template("<%= require 'base64'; Base64.strict_encode64('${docker_username}:${docker_password}') -%>")

    $docker_config = {
        'auths' => {
            "${docker_registry}" => {
                'auth' => $docker_auth,
            }
        }
    }

    file { '/root/.docker':
        ensure => directory,
        owner  => 'root',
        group  => 'docker',
        mode   => '0550',
    }

    file { '/root/.docker/config.json':
        content => ordered_json($docker_config),
        owner   => 'root',
        group   => 'docker',
        mode    => '0440',
        notify  => Service['docker'],
        require => File['/root/.docker'],
    }
    # Temporarily build kubernetes too! We'll eventually have this
    # be done somewhere else.
    include ::toollabs::kubebuilder

    ferm::service { 'kubebuilder-http':
        port  => '80',
        proto => 'tcp',
    }
}
