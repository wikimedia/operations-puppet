# == Class: mediawiki::jobrunner
#
# jobrunner continuously processes the MediaWiki job queue by dispatching
# workers to perform tasks and monitoring their success or failure.
#
class mediawiki::jobrunner (
	$aggr_servers,
	$queue_servers
	$runners_basic = 1,
	$runners_upload = 1,
	$runners_gwt = 1,
	$runners_parsoid = 1,
	$runners_transcode = 1
) {
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

    file { '/etc/jobrunner.ini':
        content => template('mediawiki/jobrunner.ini.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['jobrunner'],
    }

    service { 'jobrunner':
        ensure   => 'running',
        provider => 'upstart',
    }
}
