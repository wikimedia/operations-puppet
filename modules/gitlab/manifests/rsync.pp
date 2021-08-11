# sets up rsync of backups between 2 GitLab servers
# activates rsync for push from the primary to secondary
# T285867
class gitlab::rsync (
    $active_host,
    $passive_host,
    $ensure
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
        path           => '/srv/gitlab-backup/latest/',
        read_only      => 'no',
        hosts_allow    => [$active_host],
        auto_ferm      => true,
        auto_ferm_ipv6 => true,
    }

    rsync::server::module { 'config-backup':
        ensure         => $ensure_sync,
        path           => '/etc/gitlab/config_backup/latest/',
        read_only      => 'no',
        hosts_allow    => [$active_host],
        auto_ferm      => true,
        auto_ferm_ipv6 => true,
    }

    systemd::timer::job { 'rsync-data-backup':
        ensure      => $ensure_job,
        user        => 'root',
        description => 'rsync GitLab data backup primary to a secondary server',
        command     => "/usr/bin/rsync -avp --delete /srv/gitlab-backup/latest/ rsync://${passive_host}/data-backup",
        interval    => {'start' => 'OnCalendar', 'interval' => '*-*-* 01:00:00'},
    }
    systemd::timer::job { 'rsync-config-backup':
        ensure      => $ensure_job,
        user        => 'root',
        description => 'rsync GitLab config backup primary to a secondary server',
        command     => "/usr/bin/rsync -avp --delete /etc/gitlab/config_backup/latest/ rsync://${passive_host}/config-backup",
        interval    => {'start' => 'OnCalendar', 'interval' => '*-*-* 01:00:00'},
    }
}
