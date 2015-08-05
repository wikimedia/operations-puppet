class k8s::flannel(
    $etcd_endpoints,
    $etcd_prefix='/coreos.com/network/',
) {
    # Ugly ugly haaaacccckkkkkk
    # This will eventually be packaged
    file { '/usr/local/bin/flanneld':
        source => '/data/scratch/k8s/flannel/bin/flanneld',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    base::service_unit { 'flannel':
        systemd => true,
    }
}
