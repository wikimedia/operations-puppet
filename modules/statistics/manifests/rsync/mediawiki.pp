# == Class statistics::rsync::mediawiki
#
# Sets up daily cron jobs to rsync log files from remote
# logging hosts to a local destination for further processing.
#
class statistics::rsync::mediawiki {
    Class['::statistics'] -> Class['::statistics::rsync::mediawiki']
    $working_path = $::statistics::working_path

    # Any logs older than this will be pruned by
    # the rsync_job define.
    $retention_days = 90

    file { "${working_path}/mw-log":
        ensure  => 'directory',
        owner   => 'stats',
        group   => 'wikidev',
        mode    => '0775',
    }

    # Search request logs from fluorine
    statistics::rsync_job { 'CirrusSearchRequests':
        source         => 'fluorine.eqiad.wmnet::mw-log/archive/CirrusSearchRequests.*.gz',
        destination    => "${working_path}/mw-log/archive",
        retention_days => $retention_days,
    }
}
