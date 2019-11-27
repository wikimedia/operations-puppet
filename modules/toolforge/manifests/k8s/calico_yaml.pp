class toolforge::k8s::calico_yaml(
    String              $pod_subnet,
    String              $calico_version = 'v3.8.0',
    String              $calicoctl_sha = 'e4074ba195baa36955f378998f0bc7f3486580a7999c9038ce9bfcd1430592a2',
) {
    require ::toolforge::k8s::kubeadm

    file { 'calicoctl-binary':
        ensure         => file,
        path           => '/usr/local/bin/calicoctl',
        owner          => 'root',
        group          => 'root',
        mode           => '0555',
        source         => "https://github.com/projectcalico/calicoctl/releases/download/${calico_version}/calicoctl",
        checksum_value => $calicoctl_sha,
        checksum       => 'sha256',
    }

    file { '/etc/kubernetes/calico.yaml':
        ensure  => present,
        content => template('toolforge/k8s/calico.yaml.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        require => File['/etc/kubernetes'],
    }
}
