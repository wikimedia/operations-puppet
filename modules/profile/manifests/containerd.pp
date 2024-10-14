# SPDX-License-Identifier: Apache-2.0
# @summary
#   Install and configure containerd for kubernetes
class profile::containerd (
  Wmflib::Ensure $ensure = lookup('profile::containerd::ensure', { 'default_value' => present }),
  String $kubernetes_cluster_name = lookup('profile::kubernetes::cluster_name'),
  Optional[String] $registry_username = lookup('profile::containerd::registry_username', { 'default_value' => 'kubernetes' }),
  Optional[String] $registry_password = lookup('profile::containerd::registry_password', { 'default_value' => undef }),
) {
  $k8s_config = k8s::fetch_cluster_config($kubernetes_cluster_name)
  ensure_packages(['crictl'])

  # Check if dragonfly::dfdaemon is configured for this host
  if defined(Class['profile::dragonfly::dfdaemon']) {
    $dragonfly_enabled = $profile::dragonfly::dfdaemon::ensure ? {
      'absent'  => false,
      default   => true,
    }
  } else {
    $dragonfly_enabled = false
  }
  class { 'containerd::configuration':
    ensure            => $ensure,
    sandbox_image     => $k8s_config['infra_pod'],
    dragonfly_enabled => $dragonfly_enabled,
    registry_username => $registry_username,
    registry_password => $registry_password,
  }

  class { 'containerd':
    ensure => $ensure,
  }

  class { 'containerd::nerdctl':
    ensure => $ensure,
  }
}
