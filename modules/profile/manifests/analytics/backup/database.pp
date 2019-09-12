# == Class: profile::analytics::backup::database
#
# Periodical backups of all the databases using Bacula. This profile
# is generic enough to be re-used across multiple Analytics database
# environments (like Piwik/Meta/etc..).
#
# Assumptions for Analytics databases:
# 1) no slaves are set up
# 2) lock time due to mysqldump is acceptable
# 3) xtrabackup is not used
#
# == Parameters
#
# [*backup_username*]
#   Mysql username used to execute mysqldump of all the databases.
#   Must be set manually on the database before setting this class up.
#
# [*backup_password*]
#   Mysql username's password used to execute mysqldump of all the databases.
#   Must be set manually on the database before setting this class up.
#
# [*db_instance*]
#   Name of the target database, mostly for puppet-naming puroposes.
#   If undef, it defaults to $title.
#
# [*backup_frequency*]
#   How often the backup should be taken. Keep in mind that a more frequent
#   backup scheduling will generate more files to be stored on disk.
#   Default: 'Weekly'
#   Supported values: 'Daily', 'Weekly'
#
class profile::analytics::backup::database (
    String $backup_username = lookup('profile::analytics::backup::database::username'),
    String $backup_password = lookup('profile::analytics::backup::database::password'),
    Optional[String] $db_instance = lookup('profile::analytics::backup::database::db_instance', { 'default_value' => undef }),
    Optional[String] $backup_frequency = lookup('profile::analytics::backup::database::backup_frequency', { 'default_value' => 'Weekly' }),
) {

    $supported_backup_frequency = ['Daily', 'Weekly']

    if ! ($backup_frequency in $supported_backup_frequency) {
        fail("The backup_frequency ${backup_frequency} parameter must be either Weekly or Daily")
    }

    if $backup_username and $backup_password {
        include ::profile::backup::host

        file { '/srv/backups':
            ensure => directory,
            owner  => 'root',
            group  => 'root',
            mode   => '0600', # implicitly 0700 for dirs
        }

        file { '/etc/mysql/conf.d/dumps.cnf':
            ensure  => present,
            owner   => 'root',
            group   => 'root',
            mode    => '0400',
            content => "[client]\nuser=${backup_username}\npassword=\'${backup_password}\'\n",
        }

        $db_instance_name = $db_instance ? {
            undef   => $title,
            default => $db_instance,
        }

        # Backups older than 15 days will be deleted by the predump script before
        # the mysqldump, so a cron is not needed.
        backup::mysqlset { $db_instance_name:
            xtrabackup       => false,
            per_db           => true,
            innodb_only      => true,
            binlog           => false,
            slave            => false,
            local_dump_dir   => '/srv/backups',
            password_file    => '/etc/mysql/conf.d/dumps.cnf',
            method           => 'predump',
            mysql_binary     => '/usr/bin/mysql',
            mysqldump_binary => '/usr/bin/mysqldump',
            jobdefaults      => "${backup_frequency}-${profile::backup::host::day}-${profile::backup::host::pool}",
        }
    }
}
