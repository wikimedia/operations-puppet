# SPDX-License-Identifier: Apache-2.0
class profile::dragonfly::dfdaemon (
    Wmflib::Ensure $ensure = lookup('profile::dragonfly::dfdaemon::ensure'),
    Array[String] $supernodes = lookup('profile::dragonfly::dfdaemon::supernodes'),
    Stdlib::Fqdn  $docker_registry_fqdn = lookup('profile::dragonfly::dfdaemon::docker_registry_fqdn'),
    Array[String] $proxy_urls_regex = lookup('profile::dragonfly::dfdaemon::proxy_urls_regex'),
    String $ratelimit = lookup('profile::dragonfly::dfdaemon::ratelimit'),
) {
  # TODO: add a global hiera variable called docker_registry_fqdn and use it in the other
  #       places where we refer to it explicitly in hiera.

  # Generate a certificate to hijack/MITM requests to docker-registry as well as
  # accept connections via localhost.
  #
  # With ensure == 'absent' get_cert fails because the user (owner) does not exist:
  # Error: Could not execute posix command: Invalid user: dragonfly
  # The user (and /etc/dragonfly) is created by the debian package which will not be installed
  # in case of ensure == 'absent'
  if $ensure == 'present' {
    $ssl_paths = profile::pki::get_cert('discovery', $facts['fqdn'], {
      'ensure'          => $ensure,
      'owner'           => 'dragonfly',
      'outdir'          => '/etc/dragonfly',
      'hosts'           => [$facts['hostname'], $facts['fqdn'], $docker_registry_fqdn, '127.0.0.1', '::1', 'localhost'],
      'notify_services' => ['dragonfly-dfdaemon'],
    })
  } else {
    # Create a dummy so that dragonfly::dfdaemon receives valid paths
    $ssl_paths = {
      'chained' => '/nonexistent',
      'cert' => '/nonexistent',
      'key' => '/nonexistent',
    }
  }

  class { 'dragonfly::dfdaemon':
    ensure               => $ensure,
    supernodes           => $supernodes,
    dfdaemon_ssl_cert    => $ssl_paths['chained'],
    dfdaemon_ssl_key     => $ssl_paths['key'],
    docker_registry_fqdn => $docker_registry_fqdn,
    proxy_urls_regex     => $proxy_urls_regex,
    ratelimit            => $ratelimit,
    containerd_cri       => !defined(Class['profile::docker::engine']),
  }

  # This is the port dfget (called by dfdaemon) will listen and serve chunks on.
  # dfdaemon itself does not receive connections from outside.
  firewall::service { 'dragonfly_dfget':
    ensure   => $ensure,
    proto    => 'tcp',
    port     => 15001,
    src_sets => ['DOMAIN_NETWORKS'],
  }

  # TODO: Add monitoring
}
