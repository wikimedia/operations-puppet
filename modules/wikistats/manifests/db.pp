# the database server setup for the wikistats site
class wikistats::db (
    String $db_pass,
    Stdlib::Unixpath $backupdir = '/usr/lib/wikistats/backup',
) {

    require_package('mariadb-server', 'php7.0-mysql')

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

    # (random) db pass is stored here to that deployment-script can
    # get it and replace it in the config file after deploying
    file { '/usr/lib/wikistats/wikistats-db-pass':
        ensure  => 'present',
        owner   => 'wikistatsuser',
        group   => 'wikistatsuser',
        mode    => '0400',
        content => $db_pass,
    }

    # database schema
    file { '/usr/lib/wikistats/schema.sql':
        ensure => 'present',
        owner  => 'wikistatsuser',
        group  => 'wikistatsuser',
        mode   => '0444',
        source => 'puppet:///modules/wikistats/schema.sql',
    }

    # import db schema on the first run
    exec { 'bootstrap-mysql-schema':
        command => '/usr/bin/mysql -u root -Bs < /usr/lib/wikistats/schema.sql',
        user    => 'root',
        timeout => '30',
        unless  => '/usr/bin/test -f /usr/lib/wikistats/db_init_done',
        before  => File['/usr/lib/wikistats/db_init_done'],
        require => File['/usr/lib/wikistats/schema.sql'],
    }

    file { '/usr/lib/wikistats/db_init_done':
        ensure  => 'present',
        content => 'database has been initialized',
        owner   => 'wikistatsuser',
        group   => 'wikistatsuser',
        mode    => '0444',
    }

    # grant db permissions on the first run

    file { '/usr/lib/wikistats/grants.sql':
        ensure  => 'present',
        content => template('wikistats/db/grants.sql.erb'),
        owner   => 'wikistatsuser',
        group   => 'wikistatsuser',
        mode    => '0444',
    }

    exec { 'bootstrap-mysql-grants':
        command => '/usr/bin/mysql -u root -Bs < /usr/lib/wikistats/grants.sql',
        user    => 'root',
        timeout => '30',
        unless  => '/usr/bin/test -f /usr/lib/wikistats/db_grants_done',
        before  => File['/usr/lib/wikistats/db_grants_done'],
        require => File['/usr/lib/wikistats/grants.sql'],
    }

    file { '/usr/lib/wikistats/db_grants_done':
        ensure  => 'present',
        content => 'database grants have been applied',
        owner   => 'wikistatsuser',
        group   => 'wikistatsuser',
        mode    => '0444',
    }

}
