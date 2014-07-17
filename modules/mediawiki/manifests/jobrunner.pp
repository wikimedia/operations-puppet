# == Class: mediawiki::jobrunner
#
# jobrunner continuously processes the MediaWiki job queue by dispatching
# workers to perform tasks and monitoring their success or failure.
#
class mediawiki::jobrunner (
    $queue_servers,
    $aggr_servers      = $queue_servers,
    $runners_basic     = 1,
    $runners_upload    = 1,
    $runners_gwt       = 1,
    $runners_parsoid   = 1,
    $runners_transcode = 0,
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
        mode   => '0555',
        before => Service['jobrunner']
    }

    file { '/etc/jobrunner/jobrunner.ini':
        content => template('mediawiki/jobrunner.ini.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['jobrunner'],
    }

    file { '/etc/jobrunner.ini':
        ensure  => absent,
        require => Service['jobrunner'],
    }

    service { 'jobrunner':
        ensure   => 'running',
        provider => 'upstart',
    }

    file { '/etc/logrotate.d/mediawiki_jobrunner':
        source  => 'puppet:///modules/mediawiki/logrotate.d_mediawiki_jobrunner',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }
}
