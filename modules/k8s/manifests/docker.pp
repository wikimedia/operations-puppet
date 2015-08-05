# = Class: k8s::docker
#
# Sets up docker as used by kubernetes
class k8s::docker {
    require_package('docker.io')
}
