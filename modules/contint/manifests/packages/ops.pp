# == Class contint::packages::ops
#
# Provides packages that are needed for some Operations related jobs. It is
# used for building the Nodepool diskimages.
class contint::packages::ops {

    # Do NOT use requires_os() here
    # The class is used to create diskimages and requires_os() is not
    # available in that context.
    if $::operatingsystem == 'Ubuntu' {
        fail('contint::packages::ops is not meant for Ubuntu')
    }

    # Python test suite for operations/software/conftool
    package { ['etcd', 'python-etcd']:
        ensure => latest,
    }


    # For Jenkins job operations-dns-lint
    # Production DNS migrated to Jessie T98003
    include authdns::lint
}
