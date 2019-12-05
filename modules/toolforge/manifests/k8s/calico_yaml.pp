class toolforge::k8s::calico_yaml(
    String              $pod_subnet,
    String              $calico_version = 'v3.8.0',
) {
    require ::toolforge::k8s::kubeadm

    file { '/etc/kubernetes/calico.yaml':
        ensure  => present,
        content => template('toolforge/k8s/calico.yaml.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        require => File['/etc/kubernetes'],
    }

    file { '/etc/kubernetes/calicoctl.yaml':
        ensure  => present,
        content => template('toolforge/k8s/calicoctl.yaml.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        require => File['/etc/kubernetes'],
    }

    file { '/root/.bash_aliases':
        ensure => present,
        source => 'puppet:///modules/toolforge/k8s/root-bash-aliases',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
}
