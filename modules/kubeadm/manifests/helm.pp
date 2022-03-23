# Installs Helm 3 from the Kubeadm components
class kubeadm::helm (
) {
    require ::kubeadm::repo

    package { [ 'helm', 'helmfile', 'helm-diff' ]:
        ensure => 'present',
        tag    => 'kubeadm-k8s',
    }

    file { '/etc/profile.d/helm-config.sh':
        ensure => present,
        mode   => '0555',
        source => 'puppet:///modules/kubeadm/helm-config.sh',
    }
}
