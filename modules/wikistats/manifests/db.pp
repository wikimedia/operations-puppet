# SPDX-License-Identifier: Apache-2.0
# the database server setup for the wikistats site
class wikistats::db (
    Wmflib::Php_version $php_version,
    String $db_pass,
    String $db_name = 'wikistats',
    Stdlib::Unixpath $backupdir = '/usr/lib/wikistats/backup',
    String $dumpname = 'wikistats_db',
    Stdlib::Unixpath $mysqldump = '/usr/bin/mysqldump',
){

    ensure_packages("php${php_version}-mysql")

    # db backup
    wmflib::dir::mkdir_p('/usr/local/bin/wikistats')
    file { '/usr/local/bin/wikistats/dbdump.sh':
        ensure => 'present',
        owner  => 'wikistatsuser',
        group  => 'root',
        mode   => '0554',
        source => 'puppet:///modules/wikistats/dbdump.sh',
    }
    wmflib::dir::mkdir_p('/etc/wikistats')
    file { '/etc/wikistats/dbdump.cfg':
        ensure  => 'present',
        owner   => 'wikistatsuser',
        group   => 'wikistatsuser',
        mode    => '0444',
        content => template('wikistats/dbdump.cfg.erb'),
    }

    systemd::timer::job { 'wikistats-dbdump':
        ensure          => 'present',
        user            => 'root',
        description     => 'create a database backup',
        command         => '/usr/local/bin/wikistats/dbdump.sh',
        logging_enabled => true,
        logfile_basedir => '/var/log/wikistats/',
        logfile_name    => 'dbdump.log',
        interval        => {'start' => 'OnCalendar', 'interval' => '*-*-* 0:15:00'},
    }

    # don't run out of disk
    systemd::timer::job { 'wikistats-cleanup-mysqldump':
        ensure          => 'present',
        user            => 'root',
        description     => 'delete old dump files to avoid running out of disk space',
        command         => "/usr/bin/find ${backupdir} -name \"*.sql.gz\" -mtime +7 -exec rm {} \\;",
        logging_enabled => true,
        logfile_basedir => '/var/log/wikistats/',
        logfile_name    => 'cleanup-mysqldump.log',
        interval        => {'start' => 'OnCalendar', 'interval' => '*-*-* 23:23:00'},
    }

    # (random) db pass is stored here to that deployment-script can
    # get it and replace it in the config file after deploying
    wmflib::dir::mkdir_p('/usr/lib/wikistats')
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
