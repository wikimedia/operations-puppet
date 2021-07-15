class profile::dragonfly::dfdaemon(
    Wmflib::Ensure $ensure = lookup('profile::dragonfly::dfdaemon::ensure'),
    Array[String] $supernodes = lookup('profile::dragonfly::dfdaemon::supernodes'),
    Stdlib::Fqdn  $docker_registry_fqdn = lookup('profile::dragonfly::dfdaemon::docker_registry_fqdn'),
    Array[String] $proxy_urls_regex = lookup('profile::dragonfly::dfdaemon::proxy_urls_regex'),
){
  # TODO: add a global hiera variable called docker_registry_fqdn and use it in the other
  #       places where we refer to it explicitly in hiera.

  # Generate a certificate to hijack/MITM requests to docker-registry as well as
  # accept connections via localhost.
  $ssl_paths = profile::pki::get_cert('discovery', $facts['fqdn'], {
    'ensure' => $ensure,
    'owner'  => 'dragonfly',
    'outdir' => '/etc/dragonfly',
    'hosts'  => [$facts['fqdn'], $docker_registry_fqdn, '127.0.0.1', '::1', 'localhost']
  })

  class {'dragonfly::dfdaemon':
    ensure               => $ensure,
    supernodes           => $supernodes,
    dfdaemon_ssl_cert    => $ssl_paths['cert'],
    dfdaemon_ssl_key     => $ssl_paths['key'],
    docker_registry_fqdn => $docker_registry_fqdn,
    proxy_urls_regex     => $proxy_urls_regex,
  }

  # This is the port dfget (called by dfdaemon) will listen and serve chunks on.
  # dfdaemon itself does not receive connections from outside.
  ferm::service { 'dragonfly_dfget':
      ensure => $ensure,
      proto  => 'tcp',
      port   => '15001',
      srange => '$DOMAIN_NETWORKS',
  }

  # TODO: Add monitoring
  # TODO: Add prometheus scraping config
}
