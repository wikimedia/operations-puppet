# == Class: profile::package::builder
#
# Profile for package_builder
#
class profile::package_builder {
    include ::package_builder

    # this uses modules/rsync to
    # set up an rsync daemon service
    include rsync::server

    # Set up an rsync module to allow easy copying of pbuilder
    # results to carbon or elsewhere.  You can rsync from this like:
    #   rsync <host>::pbuilder-result/jessie-amd64/mypackage* ./mypackage/
    rsync::server::module { 'pbuilder-result':
        path        => '/var/cache/pbuilder/result',
    }

    # Allow rsync
    ferm::service { 'package_builder_rsync':
        proto => 'tcp',
        port  => 873,
    }
    monitoring::service { 'package_builder_rsync':
        description   => 'package builder rsync',
        check_command => 'check_tcp!873',
    }
}
