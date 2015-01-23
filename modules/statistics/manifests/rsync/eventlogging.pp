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

    file { "${working_path}/eventlogging":
        ensure  => 'directory',
        owner   => 'stats',
        group   => 'wikidev',
        mode    => '0775',
    }

    # eventlogging logs from vanadium
    statistics::rsync_job { 'eventlogging':
        source         => 'vanadium.eqiad.wmnet::eventlogging/archive/*.gz',
        destination    => "${working_path}/eventlogging/archive",
        retention_days => $retention_days,

    }
}