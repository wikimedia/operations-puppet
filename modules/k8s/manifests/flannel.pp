class k8s::flannel(
    $etcd_endpoints,
) {
    require_package('flannel')

    base::service_unit { 'flannel':
        systemd => true,
    }

    ferm::service { 'flannel-vxlan':
        proto => udp,
        port  => 8472,
    }
}
