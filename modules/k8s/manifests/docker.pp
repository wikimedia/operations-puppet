# = Class: k8s::docker
#
# Sets up docker as used by kubernetes
class k8s::docker {
    require_package('docker.io')

    file { '/etc/default/docker':
        source => 'puppet:///modules/k8s/docker.default',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        notify => Service['docker'],
    }
}
