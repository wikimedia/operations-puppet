# SPDX-License-Identifier: Apache-2.0
# Installs Helm 3 from the Kubeadm components
class kubeadm::helm (
) {
    package { [ 'helm317', 'helmfile', 'helm-diff' ]:
        ensure => 'present',
    }

    alternatives::select { 'helm':
        path => '/usr/bin/helm3.17',
    }

    package { 'helm':
        ensure => absent,
    }

    file { '/usr/local/bin/helm-sudo':
        ensure => present,
        mode   => '0555',
        source => 'puppet:///modules/kubeadm/helm-sudo.sh',
    }

    systemd::environment { 'helm':
        variables => {
            # Let's not set full HELM_HOME so that full root isn't needed to run
            # Helm (per-user caches and repositories), but still load plugins
            # installed from Apt and (as a side effect) block non-roots from
            # manually installing plugins.
            'HELM_PLUGINS'             => '/etc/helm/plugins',
            # Configure the default Helmfile 'environment' to the current VPS project,
            # so that we can more easily apply per-project (tools, toolsbeta, paws, ...)
            # settings in our Helmfiles
            # for more details, see: https://github.com/roboll/helmfile#environment
            'HELMFILE_ENVIRONMENT'     => $::wmcs_project,
            # Keep helm diffs to a sensible size
            'HELM_DIFF_OUTPUT_CONTEXT' => '5',
        },
    }
}
