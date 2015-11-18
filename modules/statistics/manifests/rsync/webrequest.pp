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


    # NOTE: The following jobs may be removed once they are all
    #       ensured to be absent.


    # The following logs can be
    # API logs from erbium
    statistics::rsync_job { 'api':
        source      => 'erbium.eqiad.wmnet::udp2log/webrequest/archive/api-usage*.gz',
        destination => "${working_path}/squid/archive/api",
        # udp2log on eribum has been disabled
        ensure      => 'absent'
    }

    # sampled-1000 logs from erbium
    statistics::rsync_job { 'sampled_1000':
        source      => 'erbium.eqiad.wmnet::udp2log/webrequest/archive/sampled-1000*.gz',
        destination => "${working_path}/squid/archive/sampled",
        # udp2log on eribum has been disabled
        ensure      => 'absent'
    }

    # glam_nara logs from erbium
    statistics::rsync_job { 'glam_nara':
        source      => 'erbium.eqiad.wmnet::udp2log/webrequest/archive/glam_nara*.gz',
        destination => "${working_path}/squid/archive/glam_nara",
        # udp2log on eribum has been disabled
        ensure      => 'absent'
    }
}
