# = Class; graphite::wmcs::archiver
#
# Sets up a systemd timer that clears metrics from killed instances every
# hour
class graphite::wmcs::archiver {

    # FIXME: no logrotate config?

    # logging file used by the script
    file { '/var/log/graphite/instance-archiver.log':
        ensure => present,
        owner  => '_graphite',
        group  => '_graphite',
        mode   => '0644',
    }

    # prevent some log spam if the delete job is run before the script
    file { '/srv/carbon/whisper/archived_metrics':
        ensure => directory,
        owner  => '_graphite',
        group  => '_graphite',
    }

    ensure_packages('python-yaml')

    file { '/usr/local/bin/archive-instances':
        source => 'puppet:///modules/graphite/archive-instances.py',
        owner  => '_graphite',
        group  => '_graphite',
        mode   => '0700',
    }

    systemd::timer::job { 'archive-deleted-instances':
        ensure          => present,
        description     => 'Regular jobs for archiving deleted instance',
        user            => '_graphite',
        command         => '/usr/local/bin/archive-instances',
        logging_enabled => false,
        interval        => {'start' => 'OnCalendar', 'interval' => '*-*-* 13:00:00'},
        require         => File['/usr/local/bin/archive-instances'],
    }

    # Clean up archives more than a 90 days old
    systemd::timer::job { 'delete-old-instance-archives':
        ensure      => present,
        description => 'Regular jobs for deleting old instance archives',
        user        => '_graphite',
        command     => '/usr/bin/find /srv/carbon/whisper/archived_metrics -mindepth 2 -maxdepth 2 -mtime +90 -type d -exec /bin/rm -rf \'{}\' \;',
        interval    => {'start' => 'OnCalendar', 'interval' => '*-*-* 12:00:00'},
    }
}
