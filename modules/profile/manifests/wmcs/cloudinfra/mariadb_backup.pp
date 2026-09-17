# @summary Take backups of the cloudinfra MariaDB databases
# SPDX-License-Identifier: Apache-2.0
class profile::wmcs::cloudinfra::mariadb_backup (
    Stdlib::Host     $db_host          = lookup('profile::wmcs::cloudinfra::mariadb_backup::db_host'),
    String[1]        $db_username      = lookup('profile::wmcs::cloudinfra::mariadb_backup::db_username', {default_value => 'backup'}),
    String[1]        $db_password      = lookup('profile::mariadb::grants::cloudinfra::backup_pass'),
    Array[String[1]] $backup_databases = lookup('profile::wmcs::cloudinfra::mariadb_backup::backup_databases', {default_value => ['labspuppet', 'webproxy']}),
) {
    include profile::mariadb::packages_client
    mariadb::config::client { 'backups':
        path => '/etc/my.cnf',
        host => $db_host,
        port => 3306,
        user => $db_username,
        pass => $db_password,
    }

    wmflib::dir::mkdir_p('/srv/backup/mariadb')

    file { '/usr/local/sbin/backup-mariadb':
        ensure => file,
        mode   => '0555',
        source => 'puppet:///modules/profile/wmcs/cloudinfra/mariadb_backup/backup.sh',
    }

    systemd::timer::job { 'backup-mariadb':
        ensure             => present,
        user               => 'root',
        description        => 'create a backup of the cloudinfra mariadb database',
        command            => "/usr/local/sbin/backup-mariadb ${backup_databases.join(' ')}",
        interval           => {'start' => 'OnUnitInactiveSec', 'interval' => '24h'},
        monitoring_enabled => false,
        logging_enabled    => false,
    }
}
