# == Class contint::packages::ops
#
# Provides packages that are needed for some Operations related jobs. It is
# used for building the Nodepool diskimages.
class contint::packages::ops {

    # Python test suite for operations/software/conftool
    package { ['etcd', 'python3-etcd']:
        ensure => latest,
    }

    package { ['python3-conftool']:
        ensure => latest,
    }
}
