class role::ci::k8s::node {
    require ::role::labs::lvm::srv

    base::expose_puppet_certs { '/etc/kubernetes':
        provide_private => true,
        user            => 'root',
        group           => 'root',
    }

    include ::docker
    include ::k8s::kubelet
    include ::k8s::proxy
    include ::k8s::flannel
}
