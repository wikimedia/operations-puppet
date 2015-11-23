# == Class statistics::rsync::webrequest
#
# Sets up daily cron jobs to rsync log files from remote
# logging hosts to a local destination for further processing.
#
class statistics::rsync::webrequest {
    Class['::statistics'] -> Class['::statistics::rsync::webrequest']
    $working_path = $::statistics::working_path

    # Make sure destination directories exist.
    # Too bad I can't do this with recurse => true.
    # See: https://projects.puppetlabs.com/issues/86
    # for a much too long discussion on why I can't.
    file { [
        "${working_path}/aft",
        "${working_path}/aft/archive",
        "${working_path}/public-datasets",
    ]:
        ensure => 'directory',
        owner  => 'stats',
        group  => 'wikidev',
        mode   => '0775',
    }

    # Make sure destination directories exist.
    # Too bad I can't do this with recurse => true.
    # See: https://projects.puppetlabs.com/issues/86
    # for a much too long discussion on why I can't.
    file { [
        "${working_path}/squid",
        "${working_path}/squid/archive",
        # Moving away from "squid" nonmenclature for
        # webrequest logs.  New generated log
        # files will be rsynced into /a/log.
        "${working_path}/log",
        "${working_path}/log/webrequest",
    ]:
        ensure => directory,
        owner  => 'stats',
        group  => 'wikidev',
        mode   => '0755',
    }

    # all webrequest archive logs from hdfs
    statistics::rsync_job { 'hdfs_webrequest_archive':
        source         => 'stat1002.eqiad.wmnet::hdfs-archive/webrequest/*',
        destination    => "${working_path}/log/webrequest/archive",
        retention_days => 90, # Pruning after 90 days as those logs contain private data.
    }
}
