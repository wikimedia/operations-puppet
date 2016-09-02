# = Class: role::aptly
#
# Sets up a simple aptly repo server serving over http on port 80
#
# filtertags: labs-common
class role::aptly::server {
    include ::aptly

    # Auto setup published repositories for all 3 available distros
    aptly::repo { "precise-${::labsproject}":
        publish      => true,
    }

    aptly::repo { "trusty-${::labsproject}":
        publish      => true,
    }

    aptly::repo { "jessie-${::labsproject}":
        publish      => true,
    }

    ferm::service { 'aptly':
        proto  => 'tcp',
        port   => '80',
        srange => '$DOMAIN_NETWORKS',
    }
}
