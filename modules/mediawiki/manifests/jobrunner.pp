# == Class: mediawiki::jobrunner
#
# jobrunner continuously processes the MediaWiki job queue by dispatching
# workers to perform tasks and monitoring their success or failure.
#
class mediawiki::jobrunner {
    deployment::target { 'jobrunner': }

    file { '/etc/init/jobrunner.conf':
        source => 'puppet:///modules/mediawiki/jobrunner.conf',
        notify => Service['jobrunner'],
    }

    service { 'jobrunner':
        ensure   => stopped,  # not enabled yet.
        provider => upstart,
    }
}
