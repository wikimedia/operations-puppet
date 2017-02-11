# == Class: role::package::builder
#
# Role for package_builder
#
# filtertags: labs-project-deployment-prep labs-project-packaging labs-project-tools
class role::package::builder {
    include ::package_builder
    include ::base::firewall

    system::role { 'role::package::builder':
        description => 'Debian package builder'
    }


    # this uses modules/rsync to
    # set up an rsync daemon service
    include rsync::server

    # Set up an rsync module to allow easy copying of pbuilder
    # results to carbon or elsewhere.  You can rsync from this like:
    #   rsync copper.eqiad.wmnet::pbuilder-result/jessie-amd64/mypackage* ./mypackage/
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
