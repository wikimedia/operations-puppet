# SPDX-License-Identifier: Apache-2.0
# phabricator - data syncing between servers
#
class profile::phabricator::datasync (
    Stdlib::Fqdn        $active_server = lookup('phabricator_active_server',
                        { 'default_value' => undef }),
    Array[Stdlib::Fqdn]        $passive_servers = lookup('phabricator_passive_servers',
                        { 'default_value' => undef }),
    Array[Stdlib::Fqdn] $dumps_rsync_clients = lookup('profile::phabricator::main::dumps_rsync_clients'),
    Stdlib::Unixpath    $home_sync_dir= lookup('profile::phabricator::datasync::home_sync_dir',
                        { 'default_value' => '/srv/homes' }),
){

    $phabricator_servers = [ $active_server ] + $passive_servers

    $dumps_rsync_clients_ = $dumps_rsync_clients + $passive_servers

    # Allow dumps servers to pull dump files.
    rsync::server::module { 'srv-dumps':
            path          => '/srv/dumps',
            read_only     => 'yes',
            hosts_allow   => $dumps_rsync_clients_,
            auto_firewall => true,
    }

    # Allow other phab servers to pull tarballs with home dir files.
    file { $home_sync_dir: ensure => directory,}

    file { '/usr/local/bin/backup-home-dirs':
        ensure  => present,
        content => "#!/bin/bash\nfor user in \$(ls /home); do\ntar czfv /srv/homes/\${user}-\$(hostname -s).tar.gz /home/\${user}; done",
        mode    => '0555',
        owner   => 'root',
        group   => 'root',
    }

    $timer_ensure = ($active_server == $facts['networking']['fqdn'])? {
        true    => 'present',
        default => 'absent',
    }

    systemd::timer::job { 'backup-home-dirs':
        ensure      => $timer_ensure,
        description => 'create tarballs from /home dirs into /srv/homes',
        user        => 'root',
        command     => '/usr/local/bin/backup-home-dirs',
        interval    => {'start' => 'OnCalendar', 'interval' => '*-*-* 0:10:00'},
        require     => File['/usr/local/bin/backup-home-dirs'],
    }

    rsync::quickdatacopy { 'phabricator-home-dirs':
        ensure      => present,
        auto_sync   => true,
        delete      => true,
        source_host => $active_server,
        dest_host   => $passive_servers,
        module_path => $home_sync_dir,
    }

    rsync::quickdatacopy { 'phabricator-repos':
        ensure                     => present,
        auto_sync                  => true,
        delete                     => true,
        source_host                => $active_server,
        dest_host                  => $passive_servers,
        module_path                => '/srv/repos',
        ignore_missing_file_errors => true,
    }
}
