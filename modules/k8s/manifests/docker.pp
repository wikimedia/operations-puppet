# = Class: k8s::docker
#
# Sets up docker as used by kubernetes
class k8s::docker {
    class { '::docker::engine':
        declare_service => false,
    }

    base::service_unit { 'docker':
        systemd   => true,
        subscribe => Class['::docker::engine'],
    }
}
