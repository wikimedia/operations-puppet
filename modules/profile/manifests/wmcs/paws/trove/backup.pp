# SPDX-License-Identifier: Apache-2.0
class profile::wmcs::paws::trove::backup (
    String       $dbuser = lookup('profile::wmcs::paws::trove::dbuser', {default_value => 'paws'}),
    String       $dbpass = lookup('profile::wmcs::paws::trove::dbpass', {default_value => 'notarealpassword'}),
    Stdlib::Fqdn $dbhost = lookup('profile::wmcs::paws::trove::dbhost', {default_value => 'q45euqdu26j.svc.trove.eqiad1.wikimedia.cloud'}),
    Stdlib::UnixPath $backupdir = lookup('profile::wmcs::paws::trove::backupdir', {default_value => '/data/project/dbbackups'}),
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
        content => template('profile/wmcs/paws/trove/dbdump.sh.erb'),
    }

    file { '/etc/dbdump.cfg':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0440',
        content => template('profile/wmcs/paws/trove/dbdump.cfg.erb'),
    }

    file { '/var/log/paws':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    systemd::timer::job { 'paws-dbdump':
        ensure            => 'present',
        user              => 'root',
        description       => 'create a database backup',
        command           => '/usr/local/bin/dbdump.sh',
        logging_enabled   => true,
        logfile_basedir   => '/var/log/paws/',
        logfile_name      => 'dbdump.log',
        syslog_identifier => 'pawsdumps',
        interval          => {'start' => 'OnCalendar', 'interval' => '*-*-* 0:15:00'},
    }

    systemd::timer::job { 'paws-cleanup-mysqldump':
        ensure            => 'present',
        user              => 'root',
        description       => 'delete old dump files to avoid running out of disk space',
        command           => "/usr/bin/find ${backupdir} -name \"*.sql.gz\" -mtime +7 -exec rm {} \\;",
        logging_enabled   => true,
        logfile_basedir   => '/var/log/paws/',
        logfile_name      => 'cleanup-mysqldump.log',
        syslog_identifier => 'pawsdumps-cleanup',
        interval          => {'start' => 'OnCalendar', 'interval' => '*-*-* 23:23:00'},
    }
}
