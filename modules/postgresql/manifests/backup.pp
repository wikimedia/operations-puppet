# @summary postgresql::backup
#
#   Provides a way to add backups for postgresql databases
#   Uses pg_dumpall to dump all databases and meta information.
#
# @param dump_interval how often to perform dumps (in a systemd timer syntax). Default: once a day.
# @param path Full path to a directory to dump to. No ending slash. default: /srv/postgres-backup
# @param rotate_days Number of days after which old backups are deleted. default: 7
# @param do_backups If we should perform backups (False will remove the systemd timer). Default: True

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

    String            $dump_interval = '*-*-* 01:23:00',
    Stdlib::Unixpath  $path = '/srv/postgres-backup',
    Integer           $rotate_days = 7,
    Boolean           $do_backups = true,
) {

    file { $path:
        ensure => 'directory',
        owner  => 'postgres',
        group  => 'postgres',
        mode   => '0750',
    }

    # Keep the file in case manual dump need to be done even if $do_backups is False
    file { '/usr/local/bin/dump_all.sh':
        ensure => 'file',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/postgresql/dump_all.sh',
    }

    $active_ensure = $do_backups.bool2str('present', 'absent')
    systemd::timer::job { 'postgres-dump':
        ensure      => $active_ensure,
        description => 'Regular jobs to dump all databases and meta information',
        user        => 'postgres',
        command     => "/usr/local/bin/dump_all.sh ${path}",
        interval    => {
            'start'    => 'OnCalendar',
            'interval' => $dump_interval,

        },
    }

    $clean_hour = fqdn_rand(23, 'pgclean')
    $clean_minute = fqdn_rand(59, 'pgclean')

    systemd::timer::job { 'rotate-postgres-dump':
        ensure      => $active_ensure,
        description => 'Regular jobs to clean up old dumps',
        user        => 'postgres',
        command     => "/usr/bin/find ${path} -type f -name '*.sql.gz' -mtime +${rotate_days} -delete",
        interval    => {
            'start'    => 'OnCalendar',
            'interval' => "*-*-* ${clean_hour}:${clean_minute}:00",
        },
    }
}
