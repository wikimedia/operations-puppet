# the database server setup for the wikistats site
class wikistats::db {

    package { [ 'mariadb-server', 'php5-mysql']:
        ensure => present,
    }

    # db backup
    cron { 'mysql-dump-wikistats':
        ensure  => 'present',
        command => "/usr/bin/mysqldump -u wikistatsuser -p${db_pass} wikistats > ${backup_dir}/wikistats_db_${date}.sql",
        user    => 'wikistatsusers',
        hour    => '0',
        minute  => '15',
    }

    # don't run out of disk
    cron {'mysql-dump-wikistats-clean':
        ensure  => 'present',
        command => "find ${backupdir} -name \"*.sql.gz\" -mtime +7 -exec rm {} \;",
        user    => 'wikistatsuser',
        hour    => '23',
        minute  => '23',
    }
}
