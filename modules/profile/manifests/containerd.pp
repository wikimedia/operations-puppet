# SPDX-License-Identifier: Apache-2.0
# @summary
#   Install and configure containerd for kubernetes
class profile::containerd (
  Wmflib::Ensure $ensure = lookup('profile::containerd::ensure', { 'default_value' => absent }),
  String $kubernetes_cluster_name = lookup('profile::kubernetes::cluster_name'),
  Optional[String] $registry_auth = lookup('profile::containerd::registry_auth', { 'default_value' => undef }),
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
    registry_auth     => $registry_auth,
    dragonfly_enabled => $dragonfly_enabled,
  }

  class { 'containerd':
    ensure => $ensure,
  }

  class { 'containerd::nerdctl':
    ensure => $ensure,
  }
}
