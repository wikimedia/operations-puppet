class profile::dragonfly::supernode {
  class {'dragonfly::supernode': }

  # This is the port the supernode is listening on for dfget clients to connect
  # Prometheus metrics are served here as well (/metrics)
  ferm::service { 'dragonfly_supernode':
      proto  => 'tcp',
      port   => '8002',
      srange => '$DOMAIN_NETWORKS',
  }

  # TODO: Add icinga monitoring
}
