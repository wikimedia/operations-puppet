class role::ci::k8s::master {
    # run the etcd server on the master for now
    include ::etcd

    base::expose_puppet_certs { '/etc/kubernetes':
        provide_private => true,
        user            => 'kubernetes',
        group           => 'kubernetes',
    }

    include ::k8s::apiserver
    include ::k8s::scheduler
    include ::k8s::controller

    # stub tokenauth file for manual management
    # (in toollabs it's populated by the maintain-kubeusers daemon)
    file { '/etc/kubernetes/tokenauth':
        ensure => present,
    }
}
