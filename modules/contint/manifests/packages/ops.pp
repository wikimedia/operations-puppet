# == Class contint::packages::ops
#
# Provides packages that are needed for some Operations related jobs. It is
# used for building the Nodepool diskimages.
class contint::packages::ops {

    # Python test suite for operations/software/conftool
    package { ['etcd', 'python-etcd']:
        ensure => latest,
    }

    package { ['python-conftool']:
        ensure => latest,
    }


    # For Jenkins job operations-dns-lint
    # Production DNS migrated to Jessie T98003
    include ::authdns::lint
}
