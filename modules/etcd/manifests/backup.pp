# === Class etcd::backup
#
# Creates regular backups of etcd on disk
#

class etcd::backup ($cluster_name=$::domain, $backup_dir='/srv/backups/etcd') {
    file { ['/srv/backups', $backup_dir]:
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { '/usr/local/bin/etcd-backup':
        source => 'puppet:///modules/etcd/etcd-backup.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    $backup_minute = fqdn_rand(60, 'etcd_backup')

    systemd::timer::job { 'etcd-backup':
        ensure             => present,
        user               => 'root',
        description        => 'create a backup of etcd data',
        command            => "/usr/local/bin/etcd-backup ${cluster_name} ${backup_dir}",
        interval           => {'start' => 'OnCalendar', 'interval' => "*-*-* *:${backup_minute}:0"},
        monitoring_enabled => true,
        logging_enabled    => false,
    }
}
