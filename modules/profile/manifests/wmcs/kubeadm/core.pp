# SPDX-License-Identifier: Apache-2.0
# Installs a container runtime and the core kubeadm tool
class profile::wmcs::kubeadm::core (
    String $component = lookup('profile::wmcs::kubeadm::component', {default_value => 'thirdparty/kubeadm-k8s-1-21'}),
    Optional[Stdlib::Fqdn] $label_custom_domain = lookup('profile::wmcs::kubeadm::label_custom_domain', {default_value => undef}),
    Boolean $mount_nfs = lookup('mount_nfs', {default_value => false}),
) {
    class { '::kubeadm::repo':
        component => $component,
    }

    class { '::kubeadm::docker': }

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

    class { '::kubeadm::calico_workaround': }
}
