# == Class: mediawiki::jobrunner
#
# jobrunner continuously processes the MediaWiki job queue by dispatching
# workers to perform tasks and monitoring their success or failure.
#
class mediawiki::jobrunner (
    $queue_servers,
    $aggr_servers      = $queue_servers,
    $runners_basic     = 0,
    $runners_upload    = 0,
    $runners_gwt       = 0,
    $runners_parsoid   = 0,
    $runners_transcode = 0,
    $statsd_server     = undef,
) {
    include ::passwords::redis

    deployment::target { 'jobrunner': }

    file { '/etc/default/jobrunner':
        source => 'puppet:///modules/mediawiki/jobrunner.default',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        notify => Service['jobrunner'],
    }

    file { '/etc/init/jobrunner.conf':
        source => 'puppet:///modules/mediawiki/jobrunner.conf',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        notify => Service['jobrunner'],
    }

    file { '/etc/jobrunner':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        before => Service['jobrunner']
    }

    file { '/etc/jobrunner/jobrunner.conf':
        content => template('mediawiki/jobrunner.conf.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['jobrunner'],
    }

    file { '/etc/jobrunner/jobrunner.ini':
        content => template('mediawiki/jobrunner.ini.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['jobrunner'],
    }

    service { 'jobrunner':
        ensure   => running,
        provider => 'upstart',
    }

    file { '/etc/logrotate.d/mediawiki_jobrunner':
        source  => 'puppet:///modules/mediawiki/logrotate.d_mediawiki_jobrunner',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }
}
