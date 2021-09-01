# == Class profile::quarry::trove::backup
# Sets up a very simple mysqldump to NFS on a schedule since trove lacks
# native backup at this time.
#
# You must create a manual config file at /etc/dbdump.cfg that is a basic mysql
# ini file for setting the host, username and password until quarry has secrets
# management.
# Parameter backupdir is used in the templates.
class profile::quarry::trove::backup (
    Stdlib::UnixPath $backupdir = lookup('profile::quarry::trove::backupdir', {default_value => '/data/project/dbbackups'}),
){
    ensure_packages(['mariadb-client'])

    file { $backupdir:
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0700',
    }

    file { '/usr/local/bin/dbdump.sh':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0554',
        content => template('profile/quarry/trove/dbdump.sh.erb'),
    }

    file { '/usr/local/bin/dbdumpcleanup.sh':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0554',
        content => template('profile/quarry/trove/dbdumpcleanup.sh.erb'),
    }

    file { '/var/log/quarry':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    systemd::timer::job { 'quarry-dbdump':
        ensure            => 'present',
        user              => 'root',
        description       => 'create a database backup',
        command           => '/usr/local/bin/dbdump.sh',
        logging_enabled   => true,
        logfile_basedir   => '/var/log/quarry/',
        logfile_name      => 'dbdump.log',
        syslog_identifier => 'quarrydumps',
        interval          => {'start' => 'OnCalendar', 'interval' => '*-*-* 0:15:00'},
    }

    systemd::timer::job { 'quarry-cleanup-mysqldump':
        ensure            => 'present',
        user              => 'root',
        description       => 'delete old dump files to avoid running out of disk space',
        command           => '/usr/local/bin/dbdumpcleanup.sh',
        logging_enabled   => true,
        logfile_basedir   => '/var/log/quarry/',
        logfile_name      => 'cleanup-mysqldump.log',
        syslog_identifier => 'quarrydumps-cleanup',
        interval          => {'start' => 'OnCalendar', 'interval' => '*-*-* 23:23:00'},
    }
}
