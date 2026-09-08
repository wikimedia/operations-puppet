# SPDX-License-Identifier: Apache-2.0
#
# Manages configuration used by 'scap deploy-service' to enable Kubernetes service deployments.
#
# NOTE: This feature is new and entering pilot in Q2 FY26-27 (T412941). As a result, this class is
# rather minimal initially while we evaluate the configuration API.
#
class profile::kubernetes::deployment_server::deploy_service(
    Hash[String, Hash] $cluster_groups  = lookup('profile::kubernetes::deployment_server::deploy_service::cluster_groups',  { 'default_value' => {} }),
    Hash[String, Hash] $service_catalog = lookup('profile::kubernetes::deployment_server::deploy_service::service_catalog', { 'default_value' => {} }),
) {
  file { '/etc/scap/cluster-groups.yaml':
    content => to_yaml($cluster_groups),
    mode    => '0444',
  }
  file { '/etc/scap/service-catalog.yaml':
    content => to_yaml($service_catalog),
    mode    => '0444',
  }
}
