#
# Class: postgresql::backup
#
# Provides a way to add backups for postgresql.
# Uses pg_dumpall to dump all databases and meta information.
#
# Parameters:
# $path
# Full path to a directory to dump to. No ending slash. default: /srv/postgres-backup
#
# $rotate_days
# Number of days after which old backups are deleted. default: 7
#
# Requires:
# postgresql-client, pg_dumpall, gzip, find
#
# Sample Usage:
#
# class { '::postgresql::backup': }
# backup::set { 'postgresql': }
#
# Or add your custom Bacula fileset in
# modules/profile/manifests/backup/director.pp)
#
class postgresql::backup(
    String $path = '/srv/postgres-backup',
    Integer $rotate_days = 7,
    ) {

    file { $path:
        ensure => 'directory',
        owner  => 'postgres',
        group  => 'postgres',
        mode   => '0750',
    }

    cron { 'postgres-dump':
        ensure  => 'present',
        command => "/usr/bin/pg_dumpall | gzip > ${path}/psql-all-dbs-`date \"+%Y%m%d\"`.sql.gz",
        user    => 'postgres',
        hour    => fqdn_rand(23, $title),
        minute  => fqdn_rand(59, $title),
    }

    cron { 'postgres-rotate-dump':
        ensure  => 'present',
        command => "find ${path} -type f -name '*.sql.gz' -mtime +${rotate_days} -delete",
        user    => 'postgres',
        hour    => fqdn_rand(23, $title),
        minute  => fqdn_rand(59, $title),
    }
}
