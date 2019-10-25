class ceph::k8s::calico(
    String              $pod_subnet,
) {
    file { '/etc/kubernetes/calico.yaml':
        ensure  => present,
        content => template('ceph/k8s/kubeadm/calico.yaml.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        require => File['/etc/kubernetes'],
    }
}
