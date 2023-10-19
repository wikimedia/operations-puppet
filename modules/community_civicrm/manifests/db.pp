# SPDX-License-Identifier: Apache-2.0
# @summary the database server setup for the community_civicrm site
#
# @param php_version the php_version in use
# @param db_host host of where the civicrm db is located
# @param db_user civicrm admin db user
# @param db_pass password for civicrm admin db user
# @param db_name database containing the civicrm tables
# @param file_root directory path for config and status files
# @param backupdir directory path for holding backup files
# @param mysqldump path to mysqldump utility
#
class community_civicrm::db (
    Wmflib::Php_version $php_version,
    Stdlib::Host $db_host = 'localhost',
    String $db_user = 'civiadmin',
    String $db_pass = 'FAKEFAKEFAKE',
    String $db_name = 'drupal',
    Stdlib::Unixpath $file_root = '/usr/lib/community_civicrm',
    Stdlib::Unixpath $backupdir = "${file_root}/backup",
    Stdlib::Unixpath $mysqldump = '/usr/bin/mysqldump',
){

    ensure_packages("php${php_version}-mysql")

    # value used in naming the db dump file
    $dumpname = 'community_civicrm_db'

    # db backup
    file { '/usr/local/bin/community_civicrm-dbdump':
        ensure => present,
        owner  => 'civiadmin',
        mode   => '0554',
        source => 'puppet:///modules/community_civicrm/dbdump.sh',
    }
    wmflib::dir::mkdir_p('/etc/community_civicrm')
    file { '/etc/community_civicrm/dbdump.cfg':
        ensure  => present,
        owner   => 'civiadmin',
        group   => 'civiadmin',
        mode    => '0444',
        content => template('community_civicrm/dbdump.cfg.erb'),
    }

    wmflib::dir::mkdir_p('/var/log/community_civicrm')
    systemd::timer::job { 'community_civicrm-dbdump':
        ensure          => present,
        user            => 'root',
        description     => 'create a database backup',
        command         => '/usr/local/bin/community_civicrm-dbdump',
        logging_enabled => true,
        logfile_basedir => '/var/log/community_civicrm/',
        logfile_name    => 'dbdump.log',
        interval        => {'start' => 'OnCalendar', 'interval' => '*-*-* 0:15:00'},
    }

    # don't run out of disk
    systemd::timer::job { 'community_civicrm-cleanup-mysqldump':
        ensure          => present,
        user            => 'root',
        description     => 'delete old dump files to avoid running out of disk space',
        command         => "/usr/bin/find ${backupdir} -name \"*.sql.gz\" -mtime +7 -exec rm {} \\;",
        logging_enabled => true,
        logfile_basedir => '/var/log/community_civicrm/',
        logfile_name    => 'cleanup-mysqldump.log',
        interval        => {'start' => 'OnCalendar', 'interval' => '*-*-* 23:23:00'},
    }

    # (random) db pass is stored here to that deployment-script can
    # get it and replace it in the config file after deploying
    wmflib::dir::mkdir_p($file_root)
    file { "${file_root}/community_civicrm-db-pass":
        ensure    => present,
        owner     => 'civiadmin',
        group     => 'civiadmin',
        mode      => '0400',
        content   => $db_pass,
        show_diff => false,
    }

    # database schema
    file { "${file_root}/schema.sql":
        ensure => present,
        owner  => 'civiadmin',
        group  => 'civiadmin',
        mode   => '0444',
        source => 'puppet:///modules/community_civicrm/schema.sql',
    }

    # import db schema on the first run
    exec { 'bootstrap-mysql-schema':
        command => "/usr/bin/mysql -u root -Bs < ${file_root}/schema.sql",
        user    => 'root',
        timeout => '30',
        unless  => "/usr/bin/mysql -u root -Bs -D${db_name} -e 'describe civicrm_setting'",
        creates => "${file_root}/db_init_done",
        require => File["${file_root}/schema.sql"],
    }

    file { "${file_root}/db_init_done":
        ensure  => present,
        content => 'database has been initialized',
        owner   => 'civiadmin',
        group   => 'civiadmin',
        mode    => '0444',
    }

    # grant db permissions on the first run

    file { "${file_root}/grants.sql":
        ensure    => present,
        content   => template('community_civicrm/db/grants.sql.erb'),
        owner     => 'civiadmin',
        group     => 'civiadmin',
        mode      => '0444',
        show_diff => false,
    }

    exec { 'bootstrap-mysql-grants':
        command => "/usr/bin/mysql -u root -Bs < ${file_root}/grants.sql",
        user    => 'root',
        timeout => '30',
        unless  => "/usr/bin/mysql -u root -Bs -e 'show grants for \'${db_user}\'@\'${db_host}\''",
        require => File["${file_root}/grants.sql"],
    }

}
