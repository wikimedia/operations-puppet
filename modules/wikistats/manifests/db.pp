# the database server setup for the wikistats site
class wikistats::db {

    if os_version('debian >= stretch') {
        require_package('php7.0-mysql')
    } else {
        require_package('php5-mysql')
    }

    require_package('mariadb-server')

    $backupdir = '/usr/lib/wikistats/backup'

    # db backup
    cron { 'mysql-dump-wikistats':
        ensure  => 'present',
        command => "/usr/bin/mysqldump -u root wikistats > ${wikistats::db::backupdir}/wikistats_db_$(date +%Y%m%d).sql && gzip ${backupdir}/wikistats_db_$(date +%Y%m%d).sql",
        user    => 'root',
        hour    => '0',
        minute  => '15',
    }

    # don't run out of disk
    cron {'mysql-dump-wikistats-clean':
        ensure  => 'present',
        command => "find ${backupdir} -name \"*.sql.gz\" -mtime +7 -exec rm {} \\;",
        user    => 'root',
        hour    => '23',
        minute  => '23',
    }

    file { '/usr/lib/wikistats/schema.sql':
        ensure => 'present',
        user   => 'wikistatsuser',
        group  => 'wikistatsuser',
        mode   => '0444',
        source => 'puppet:///modules/wikistats/schema.sql',
    }

    exec { 'bootstrap-mysql-schema':
        command => '/usr/bin/mysql -u root -Bs < /usr/lib/wikistats/schema.sql',
        creates => '/usr/lib/wikistats/db_init',
        user    => 'root',
        timeout => '30',
    }
}
