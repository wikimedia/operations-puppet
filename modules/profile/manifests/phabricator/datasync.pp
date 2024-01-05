# SPDX-License-Identifier: Apache-2.0
# phabricator - data syncing between servers
#
class profile::phabricator::datasync (
    Array                       $phabricator_servers= lookup('phabricator_servers',
                                                      { 'default_value' => undef }),
    Array[Stdlib::Fqdn]         $dumps_rsync_clients = lookup('profile::phabricator::main::dumps_rsync_clients'),
){

    # Allow dumps servers to pull dump files.
    rsync::server::module { 'srv-dumps':
            path        => '/srv/dumps',
            read_only   => 'yes',
            hosts_allow => $dumps_rsync_clients,
            auto_nft    => true,
    }

    # Allow other phab servers to pull tarballs with home dir files.
    file { '/srv/homes': ensure => directory,}

    rsync::server::module { 'srv-homes':
            path        => '/srv/homes',
            read_only   => 'yes',
            hosts_allow => $phabricator_servers,
            auto_nft    => true,
    }

    # Allow pulling /srv/repos data from the active server.
    rsync::server::module { 'srv-repos':
        ensure      => present,
        read_only   => 'yes',
        path        => '/srv/repos',
        hosts_allow => $phabricator_servers,
        auto_nft    => true,
    }
}
