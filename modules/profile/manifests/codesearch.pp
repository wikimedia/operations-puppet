# SPDX-License-Identifier: Apache-2.0
class profile::codesearch (
    Stdlib::Unixpath $base_dir = lookup('profile::codesearch::base_dir'),
    Hash[String, Integer] $ports = lookup('profile::codesearch::ports'),
) {

    ferm::conf { 'docker-preserve':
        ensure => present,
        prio   => 20,
        source => 'puppet:///modules/codesearch/ferm/docker-preserve.conf',
    }

    ferm::service { 'codesearch':
        proto  => 'tcp',
        port   => '3002',
        # Disallow direct access from other WMCS projects. They must use the
        # stable (and rate-limited) codesearch-backend.wmcloud.org URL instead.
        #
        # Allow access from local Docker containers (e.g. codesearch-frontend)
        # https://phabricator.wikimedia.org/T361899
        srange => '($CACHES 172.17.0.0/16)',
    }

    class { '::codesearch':
        base_dir => $base_dir,
        ports    => $ports,
    }
}
