# SPDX-License-Identifier: Apache-2.0
class profile::dragonfly::supernode (
  Stdlib::Port::Unprivileged $listen_port = lookup('profile::dragonfly::supernode::listen_port'),
  Stdlib::Port::Unprivileged $download_port = lookup('profile::dragonfly::supernode::download_port'),
  Enum['local', 'source']    $cdn_pattern = lookup('profile::dragonfly::supernode::cdn_pattern'),
) {
  class {'dragonfly::supernode':
    listen_port   => $listen_port,
    download_port => $download_port,
    cdn_pattern   => $cdn_pattern,
  }

  # This is the port the supernode is listening on for dfget clients to connect
  # Prometheus metrics are served here as well (/metrics)
  firewall::service { 'dragonfly_supernode':
      proto    => 'tcp',
      port     => $listen_port,
      src_sets => ['DOMAIN_NETWORKS'],
  }

  if ($download_port != $listen_port) and ($cdn_pattern == 'local') {
    $ensure_download_port = 'present'
  } else {
    $ensure_download_port = 'absent'
  }
  firewall::service { 'dragonfly_supernode_cdn':
      ensure   => $ensure_download_port,
      proto    => 'tcp',
      port     => $download_port,
      src_sets => ['DOMAIN_NETWORKS'],
  }

  # TODO: Add icinga monitoring
}
