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
        ensure => 'directory',
        owner  => 'stats',
        group  => 'wikidev',
        mode   => '0775',
    }

    # Search request logs from fluorine
    statistics::rsync_job { 'CirrusSearchUserTesting':
        source         => 'fluorine.eqiad.wmnet::udp2log/archive/CirrusSearchUserTesting.*.gz',
        destination    => "${working_path}/mw-log/archive/CirrusSearchUserTesting",
        retention_days => $retention_days,
    }

    # Api logs from fluorine
    statistics::rsync_job { 'mw-api':
        source         => 'fluorine.eqiad.wmnet::udp2log/archive/api.log-*.gz',
        destination    => "${working_path}/mw-log/archive/api",
        # Retention of 30 days to save disk space
        retention_days => 30,
    }
}
