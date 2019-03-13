# = Class; graphite::wmcs::archiver
#
# Sets up a cron job that clears metrics from killed instances every
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

    # prevent some cronspam if the delete cronjob is run before the script
    file { '/srv/carbon/whisper/archived_metrics':
        ensure => directory,
        owner  => '_graphite',
        group  => '_graphite',
    }

    file { '/usr/local/bin/archive-instances':
        source => 'puppet:///modules/graphite/archive-instances',
        owner  => '_graphite',
        group  => '_graphite',
        mode   => '0700',
    }

    cron { 'archive-deleted-instances':
        ensure  => present,
        command => '/usr/local/bin/archive-instances',
        user    => '_graphite',
        minute  => 0,
        hour    => 13,
        require => File['/usr/local/bin/archive-instances'],
    }

    # Clean up archives more than a 90 days old
    cron { 'delete-old-instance-archives':
        ensure  => present,
        command => 'find /srv/carbon/whisper/archived_metrics -mindepth 2 -maxdepth 2 -mtime +90 -type d -exec /bin/rm -rf \'{}\' \;',
        user    => '_graphite',
        minute  => 0,
        hour    => 12,
    }
}
