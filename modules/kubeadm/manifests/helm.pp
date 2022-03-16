# Installs Helm 3 from the Kubeadm components
class kubeadm::helm (
) {
    require ::kubeadm::repo

    package { [ 'helm', 'helmfile', 'helm-diff' ]:
        ensure => 'present',
        tag    => 'kubeadm-k8s',
    }

    systemd::environment { 'helm':
        variables => {
            # Let's not set full HELM_HOME so that full root isn't needed to run
            # Helm (per-user caches and repositories), but still load plugins
            # installed from Apt and (as a side effect) block non-roots from
            # manually installing plugins.
            'HELM_PLUGINS' => '/etc/helm/plugins',
        },
    }

    file { '/etc/profile.d/helm-config.sh':
        ensure => absent,
    }
}
