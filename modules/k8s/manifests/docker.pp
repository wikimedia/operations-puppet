# = Class: k8s::docker
#
# Sets up docker as used by kubernetes
class k8s::docker {
    require_package('docker.io')

    require k8s::flannel

    base::service_unit { 'docker':
        systemd => true,
        require => Base::Service_unit['flannel'],
    }
}
