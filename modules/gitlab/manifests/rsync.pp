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
    if $ensure != 'present' {
        $ensure_job = 'absent'
        $ensure_sync = 'absent'
    }
    elsif $facts['fqdn'] == $active_host {
        $ensure_job = 'present'
        $ensure_sync = 'absent'
    } else {
        $ensure_job = 'absent'
        $ensure_sync = 'present'
    }

    rsync::server::module { 'data-backup':
        ensure         => $ensure_sync,
        path           => "${backup_dir_data}/latest/",
        read_only      => 'no',
        hosts_allow    => [$active_host],
        auto_ferm      => true,
        auto_ferm_ipv6 => true,
    }

    rsync::server::module { 'config-backup':
        ensure         => $ensure_sync,
        path           => "${backup_dir_config}/latest/",
        read_only      => 'no',
        hosts_allow    => [$active_host],
        auto_ferm      => true,
        auto_ferm_ipv6 => true,
    }

    $passive_hosts.each | Stdlib::Fqdn $passive_host | {
        systemd::timer::job { "rsync-data-backup-${passive_host}":
            ensure      => $ensure_job,
            user        => 'root',
            description => 'rsync GitLab data backup primary to a secondary server',
            command     => "/usr/bin/rsync -avp --delete ${backup_dir_data}/latest/ rsync://${passive_host}/data-backup",
            interval    => $rsync_interval,
        }
        systemd::timer::job { "rsync-config-backup-${passive_host}":
            ensure      => $ensure_job,
            user        => 'root',
            description => 'rsync GitLab config backup primary to a secondary server',
            command     => "/usr/bin/rsync -avp --delete ${backup_dir_config}/latest/ rsync://${passive_host}/config-backup",
            interval    => $rsync_interval,
        }
    }
}
