# == Class profile::calico::kubernetes
#
# Installs calico for use in a kubernetes cluster.
# This follows http://docs.projectcalico.org/v2.0/getting-started/kubernetes/installation/#manual-installation

class profile::calico::kubernetes {
    $etcd_endpoints = hiera('profile::calico::kubernetes::etcd_endpoints')
    $calico_version = hiera('profile::calico::kubernetes::calico_version')
    $registry = hiera('profile::calico::kubernetes::docker::registry')

    class { '::calico':
        etcd_endpoints => $etcd_endpoints,
        calico_version => $calico_version,
        registry       => $registry,
    }

    class { '::calico-cni':
    }
}
