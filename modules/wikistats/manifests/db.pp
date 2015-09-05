# the database server setup for the wikistats site
class wikistats::db {

    package { [ 'mariadb-server', 'php5-mysql']:
        ensure => present,
    }

    $backupdir = "/root/wsbackup"

    # db backup
    cron { 'mysql-dump-wikistats':
        ensure  => 'present',
        command => "/usr/bin/mysqldump -u root -p$ wikistats > ${backupdir}/wikistats_db_${date}.sql && gzip ${backupdir}/wikistats_db_${date}.sql",
        user    => 'root',
        hour    => '0',
        minute  => '15',
    }

    # don't run out of disk
    cron {'mysql-dump-wikistats-clean':
        ensure  => 'present',
        command => "find ${backupdir} -name \"*.sql.gz\" -mtime +7 -exec rm {} \;",
        user    => 'root',
        hour    => '23',
        minute  => '23',
    }
}
