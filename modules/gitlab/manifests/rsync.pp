# SPDX-License-Identifier: Apache-2.0
# sets up rsync of backups between 2 GitLab servers
# activates rsync for push from the primary to secondary
# T285867
class gitlab::rsync (
    Stdlib::Fqdn $active_host,
    Array[Stdlib::Fqdn] $passive_hosts          = [],
    Wmflib::Ensure $ensure                      = absent,
    Systemd::Timer::Schedule $rsync_interval    = {'start' => 'OnCalendar', 'interval' => '*-*-* 01:00:00'},
    Stdlib::Unixpath         $backup_dir_data   = '/srv/gitlab-backup',
    Stdlib::Unixpath         $backup_dir_config = '/etc/gitlab/config_backup',
){
    # only activate rsync/firewall hole on the server that is NOT active
    $ensure_sync = ($facts['networking']['fqdn'] != $active_host).bool2str($ensure, 'absent')

    # On the replica, only one folder is used for config and data
    # backup due to restrictions in writing to /etc/. So only one
    # rsync server module is needed.
    $all_hosts = $passive_hosts + $active_host
    rsync::server::module { 'data-backup':
        ensure        => $ensure_sync,
        path          => $backup_dir_data,
        read_only     => 'no',
        hosts_allow   => $all_hosts,
        auto_firewall => true,
    }

    $all_hosts.each | Stdlib::Fqdn $host | {
        # We need to ensure that systemd timeres are only active on the active host
        # and that any jobs on the old active pulling from the new active are also cleaned up
        $ensure_job = ($active_host == $facts['networking']['fqdn'] and $active_host != $host).bool2str($ensure, 'absent')
        # rsync data backup and exclude Shell scripts and config backup from sync
        systemd::timer::job { "rsync-data-backup-${host}":
            ensure      => $ensure_job,
            user        => 'root',
            description => 'rsync GitLab data backup primary to a secondary server',
            command     => "/usr/bin/rsync -avp --delete --exclude='*.sh' --exclude='gitlab_config_*.tar' ${backup_dir_data}/ rsync://${host}/data-backup",
            interval    => $rsync_interval,
            after       => 'full-backup.service',
        }
        # rsync config backup and exclude Shell scripts and data backup from sync
        systemd::timer::job { "rsync-config-backup-${host}":
            ensure      => $ensure_job,
            user        => 'root',
            description => 'rsync GitLab config backup primary to a secondary server',
            command     => "/usr/bin/rsync -avp --delete --exclude='*.sh' --exclude='*_gitlab_backup.tar' ${backup_dir_config}/ rsync://${host}/data-backup",
            interval    => $rsync_interval,
            after       => 'config-backup.service',
        }
    }
}
