# === Class etcd::backup
#
# Creates regular backups of etcd on disk
#

class etcd::backup ($cluster_name=$::domain, $backup_dir='/srv/backups/etcd') {
    file { ['/srv/backups', '/srv/backups/etcd']:
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

    cron { 'etcdbackup':
        command => "/usr/local/bin/etcd-backup ${cluster_name} ${backup_dir}",
        user    => 'root',
        hour    => 0,
        minute  => 0,
    }

}
