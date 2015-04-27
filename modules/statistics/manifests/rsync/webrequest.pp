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
        ensure  => 'directory',
        owner   => 'stats',
        group   => 'wikidev',
        mode    => '0775',
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
        ensure  => directory,
        owner   => 'stats',
        group   => 'wikidev',
        mode    => '0755',
    }

    # wikipedia zero logs from oxygen
    statistics::rsync_job { 'wikipedia_zero':
        source      => 'oxygen.wikimedia.org::udp2log/webrequest/archive/zero*.gz',
        destination => "${working_path}/squid/archive/zero",
        ensure      => 'absent',
    }

    # API logs from erbium
    statistics::rsync_job { 'api':
        source      => 'erbium.eqiad.wmnet::udp2log/webrequest/archive/api-usage*.gz',
        destination => "${working_path}/squid/archive/api",
    }

    # sampled-1000 logs from erbium
    statistics::rsync_job { 'sampled_1000':
        source      => 'erbium.eqiad.wmnet::udp2log/webrequest/archive/sampled-1000*.gz',
        destination => "${working_path}/squid/archive/sampled",
    }

    # glam_nara logs from erbium
    statistics::rsync_job { 'glam_nara':
        source      => 'erbium.eqiad.wmnet::udp2log/webrequest/archive/glam_nara*.gz',
        destination => "${working_path}/squid/archive/glam_nara",
    }

    # edit logs from oxygen
    statistics::rsync_job { 'edits':
        source      => 'oxygen.wikimedia.org::udp2log/webrequest/archive/edits*.gz',
        destination => "${working_path}/squid/archive/edits",
        ensure      => 'absent',
    }

    # mobile logs from oxygen
    statistics::rsync_job { 'mobile':
        source      => 'oxygen.wikimedia.org::udp2log/webrequest/archive/mobile*.gz',
        destination => "${working_path}/squid/archive/mobile",
        ensure      => 'absent',
    }

    # all webrequest archive logs from hdfs
    statistics::rsync_job { 'hdfs_webrequest_archive':
        source         => 'stat1002.eqiad.wmnet::hdfs-archive/webrequest/*',
        destination    => "${working_path}/log/webrequest/archive",
        retention_days => 90, # Pruning after 90 days as those logs contain private data.
    }
}
