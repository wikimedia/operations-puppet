# SPDX-License-Identifier: Apache-2.0
# The magnum capi helm drivers rely on a k8s cluster running the
#  cluster management API. This class should be applied to a VM
#  to set up that cluster.
#
# This class presumes that there is already a single-node k3s
#  cluster running, with a config in /etc/rancher/k3s/k3s.yaml.
#  This can be installed using the k3s puppet class.
#  For use with magnum this k3s.yaml must also be installed
#  in the private puppet repo as
#
#  modules/secret/secrets/openstack/<deployment>/magnum/capiservicek3s.yaml
#
# Magnum config will use that file to talk with the cluster API service node.
#
# The service node must also open port 6443 to the magnum control nodes;
#  this is typically accomplished via the cloudcontrol-to-kubernetes
#  security group.
#
class openstack::capihelm::service(
  Stdlib::HTTPSUrl $helm_repo,
  String           $cluster_api_version,
  String           $cluster_api_provider_openstack_version,
  Stdlib::HTTPSUrl $cluster_ctl_url,
  Stdlib::Host     $docker_repo_base,
) {
    $capi_install_script = '/root/setup_capi.sh'
    file { $capi_install_script:
        content => template('openstack/capihelm/setup_capi.sh.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0744',
    }

    exec { 'install cluster API':
        command => "/usr/bin/bash ${capi_install_script}",
        require => File[$capi_install_script],
        unless  => 'kubectl get deploy -A | grep capi-controller-manager',
    }
}
