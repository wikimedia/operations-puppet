# SPDX-License-Identifier: Apache-2.0
# == Class: profile::package::builder
#
# Profile for package_builder
#
class profile::package_builder {
    class { 'package_builder': }

    class { 'rsync::server': }
    # Set up an rsync module to allow easy copying of pbuilder
    # results to carbon or elsewhere.  You can rsync from this like:
    #   rsync <host>::pbuilder-result/buster-amd64/mypackage* ./mypackage/
    rsync::server::module { 'pbuilder-result':
        path        => '/var/cache/pbuilder/result',
    }

    firewall::service { 'package_builder_rsync':
        proto    => 'tcp',
        port     => 873,
        src_sets => ['DOMAIN_NETWORKS'],
    }

    monitoring::service { 'package_builder_rsync':
        description   => 'package builder rsync',
        check_command => 'check_tcp!873',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Debian_Packaging#Upload_to_Wikimedia_Repo',
    }

    prometheus::blackbox::check::tcp { 'package-builder-rsync':
        port          => 873,
        probe_runbook => 'https://wikitech.wikimedia.org/wiki/Debian_Packaging#Upload_to_Wikimedia_Repo',
    }

}
