# SPDX-License-Identifier: Apache-2.0
# phabricator - data syncing between servers
#
class profile::phabricator::datasync (
    Stdlib::Fqdn        $active_server = lookup('phabricator_active_server',
                        { 'default_value' => undef }),
    Stdlib::Fqdn        $passive_server = lookup('phabricator_passive_server',
                        { 'default_value' => undef }),
    Array[Stdlib::Fqdn] $dumps_rsync_clients = lookup('profile::phabricator::main::dumps_rsync_clients'),
    Stdlib::Unixpath    $home_sync_dir= lookup('profile::phabricator::datasync::home_sync_dir',
                        { 'default_value' => '/srv/homes' }),
){

    $phabricator_servers = [ $active_server, $passive_server ]

    # Allow dumps servers to pull dump files.
    rsync::server::module { 'srv-dumps':
            path          => '/srv/dumps',
            read_only     => 'yes',
            hosts_allow   => $dumps_rsync_clients,
            auto_firewall => true,
    }

    # Allow other phab servers to pull tarballs with home dir files.
    file { $home_sync_dir: ensure => directory,}

    rsync::quickdatacopy { 'phabricator-home-dirs':
        ensure      => present,
        auto_sync   => true,
        delete      => true,
        source_host => $active_server,
        dest_host   => $passive_server,
        module_path => $home_sync_dir,
    }

    # Allow pulling /srv/repos data from the active server.
    rsync::server::module { 'srv-repos':
        ensure        => present,
        read_only     => 'yes',
        path          => '/srv/repos',
        hosts_allow   => $phabricator_servers,
        auto_firewall => true,
    }
}
