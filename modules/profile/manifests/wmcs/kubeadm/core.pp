# SPDX-License-Identifier: Apache-2.0
# Installs a container runtime and the core kubeadm tool
class profile::wmcs::kubeadm::core (
    String $component = lookup('profile::wmcs::kubeadm::component'),
    Optional[Stdlib::Fqdn] $label_custom_domain = lookup('profile::wmcs::kubeadm::label_custom_domain', {default_value => undef}),
    Boolean $mount_nfs = lookup('mount_nfs', {default_value => false}),
) {
    class { '::kubeadm::repo':
        component => $component,
    }

    if debian::codename::eq('buster') {
        class { '::kubeadm::docker': }

        # Older versions of calico only supported iptables-legacy. Newer
        # versions (including the ones we currently run) seem to support
        # the newer iptables-nft (nft as in netfilter, not the blockchain
        # thing) variant, so we will gradually migrate to it as we migrate
        # the worker nodes from Debian 10 to Debian 12.
        class { '::kubeadm::calico_workaround': }
    } else {
        class { 'kubeadm::containerd': }
    }

    if $label_custom_domain {
        $label_base_domains = [
            $label_custom_domain,
            'kubernetes.wmcloud.org', # include this on all projects to make shared automation easier
        ]
    } else {
        $label_base_domains = ['kubernetes.wmcloud.org']
    }

    if $mount_nfs {
        $extra_labels = $label_base_domains.map |Stdlib::Fqdn $base_domain| {
            "${base_domain}/nfs-mounted=true"
        }
    } else {
        $extra_labels = []
    }

    class { '::kubeadm::core':
        extra_labels => $extra_labels,
    }
}
