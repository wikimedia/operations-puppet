class profile::aptly::server() {
    class { '::aptly': }

    # Auto setup published repositories for all available distros
    aptly::repo { "trusty-${::labsproject}":
        publish      => true,
    }

    aptly::repo { "jessie-${::labsproject}":
        publish      => true,
    }

    aptly::repo { "stretch-${::labsproject}":
        publish      => true,
    }

    ferm::service { 'aptly':
        proto  => 'tcp',
        port   => '80',
        srange => '$DOMAIN_NETWORKS',
    }
}
