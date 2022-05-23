# @summary
#   Provides a way to add backups for postgresql.
#   Uses pg_dumpall to dump all databases and meta information.
# @param path Full path to a directory to dump to. No ending slash. default: /srv/postgres-backup
#
# @param rotate_days Number of days after which old backups are deleted. default: 7
#
# @example
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

    file { '/usr/local/bin/dump_all.sh':
        ensure => 'file',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/postgresql/dump_all.sh',
    }

    $dump_hour = fqdn_rand(23, 'pgdump')
    $dump_minute = fqdn_rand(59, 'pgdump')

    systemd::timer::job { 'postgres-dump':
        ensure      => 'present',
        description => 'Regular jobs to dump all databases and meta information',
        user        => 'postgres',
        command     => "/usr/local/bin/dump_all.sh ${path}",
        interval    => {
            'start'    => 'OnCalendar',
            'interval' => "*-*-* ${dump_hour}:${dump_minute}:00",
        },
    }

    cron { 'postgres-dump':
        ensure => 'absent',
        user   => 'postgres',
    }

    $clean_hour = fqdn_rand(23, 'pgclean')
    $clean_minute = fqdn_rand(59, 'pgclean')

    systemd::timer::job { 'rotate-postgres-dump':
        ensure      => 'present',
        description => 'Regular jobs to clean up old dumps',
        user        => 'postgres',
        command     => "/usr/bin/find ${path} -type f -name '*.sql.gz' -mtime +${rotate_days} -delete",
        interval    => {
            'start'    => 'OnCalendar',
            'interval' => "*-*-* ${clean_hour}:${clean_minute}:00",
        },
    }

    cron { 'rotate-postgres-dump':
        ensure => 'absent',
        user   => 'postgres',
    }
}
