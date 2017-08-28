# == Class statistics::rsync::eventlogging
#
# Sets up daily cron jobs to rsync log files from remote
# logging hosts to a local destination for further processing.
#
class statistics::rsync::eventlogging {
    Class['::statistics'] -> Class['::statistics::rsync::eventlogging']
    $working_path = $::statistics::working_path

    # Any logs older than this will be pruned by
    # the rsync_job define.
    $retention_days = 90

    $destination = '/srv/log/eventlogging/archive'

    file { ['/srv/log/eventlogging', '/srv/log/eventlogging/archive']:
        ensure => 'directory',
        owner  => 'stats',
        group  => 'wikidev',
        mode   => '0775',
    }

    # eventlogging data logs from eventlog1001
    statistics::rsync_job { 'eventlogging':
        source         => 'eventlog1001.eqiad.wmnet::eventlogging/archive/*.gz',
        destination    => $destination,
        retention_days => $retention_days,
    }
}
