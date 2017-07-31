# = Class; graphite::labs::archiver
#
# Sets up a cron job that clears metrics from killed instances every
# hour
class graphite::labs::archiver {

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

    # Clean up archives more than a year old
    cron { 'delete-old-instance-archives':
        ensure  => present,
        command => 'find /srv/carbon/whisper/archived_metrics -mtime +366 -type f -delete',
        user    => '_graphite',
        minute  => 0,
        hour    => 12,
    }
}
