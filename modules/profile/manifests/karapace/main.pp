class profile::karapace::main (
    String $bootstrap_uri = lookup('karapace::bootstrap_uri'),
) {
    class { 'karapace':
        bootstrap_uri => $bootstrap_uri,
    }

    ferm::service { 'karapace':
        proto  => 'tcp',
        port   => '8081',
        srange => '$DOMAIN_NETWORKS',
    }
}
