#class: misc::statistics::rsync::jobs::eventlogging
#

# Sets up daily cron jobs to rsync log files from remote
# logging hosts to a local destination for further processing.
class statistics::rsync_job::eventlogging {
    file { '/a/eventlogging':
        ensure  => 'directory',
        owner   => 'stats',
        group   => 'wikidev',
        mode    => '0775',
    }

    # eventlogging logs from vanadium
    statistics::rsync_job { 'eventlogging':
        source      => 'vanadium.eqiad.wmnet::eventlogging/archive/*.gz',
        destination => '/a/eventlogging/archive',
    }

    $sets = [ 'a-eventlogging', 'home', ]
    include backup::host
    backup::set { $sets : }
}

