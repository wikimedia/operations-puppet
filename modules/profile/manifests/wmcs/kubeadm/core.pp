# SPDX-License-Identifier: Apache-2.0
# Installs a container runtime and the core kubeadm tool
class profile::wmcs::kubeadm::core (
    String[1]              $component           = lookup('profile::wmcs::kubeadm::component'),
    Optional[Stdlib::Fqdn] $label_custom_domain = lookup('profile::wmcs::kubeadm::label_custom_domain', {default_value => undef}),
    String[1]              $pause_image         = lookup('profile::wmcs::kubeadm::pause_image', {default_value => 'docker-registry.tools.wmflabs.org/pause:3.1'}),
    Boolean                $mount_nfs           = lookup('mount_nfs', {default_value => false}),
) {
    class { '::kubeadm::repo':
        component => $component,
    }

    class { 'kubeadm::containerd':
        pause_image => $pause_image,
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
        pause_image  => $pause_image,
    }
}
