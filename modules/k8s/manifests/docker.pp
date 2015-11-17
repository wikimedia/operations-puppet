# = Class: k8s::docker
#
# Sets up docker as used by kubernetes
class k8s::docker {
    package { 'docker.io':
        ensure  => present,
    }

    base::service_unit { 'docker':
        systemd => true,
    }
}
