class profile::toolforge::services::aptly() {
    class { '::aptly': }

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
