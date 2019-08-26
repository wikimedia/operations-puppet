# == Class: profile::package::builder
#
# Profile for package_builder
#
class profile::package_builder (
    Array[Stdlib::Fqdn] $prometheus_nodes = lookup('prometheus_nodes')
){
    class { '::package_builder': }

    # this uses modules/rsync to
    # set up an rsync daemon service
    class { '::rsync::server': }

    # Set up an rsync module to allow easy copying of pbuilder
    # results to carbon or elsewhere.  You can rsync from this like:
    #   rsync <host>::pbuilder-result/jessie-amd64/mypackage* ./mypackage/
    rsync::server::module { 'pbuilder-result':
        path        => '/var/cache/pbuilder/result',
    }

    ferm::service { 'package_builder_rsync':
        proto  => 'tcp',
        port   => 873,
        srange => '$DOMAIN_NETWORKS',
    }
    $prometheus_hosts = join($prometheus_nodes, ' ')
    # So prometheus blackbox exporter can monitor ssh
    ferm::service { 'ssh-prometheus':
        proto  => 'tcp',
        port   => '22',
        srange => "@resolve((${prometheus_hosts}))",
    }

    monitoring::service { 'package_builder_rsync':
        description   => 'package builder rsync',
        check_command => 'check_tcp!873',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Debian_Packaging#Upload_to_Wikimedia_Repo',
    }
}
