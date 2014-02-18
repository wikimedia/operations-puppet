# Class: misc::statistics::rsync::jobs::webrequest
#
# Sets up daily cron jobs to rsync log files from remote
# logging hosts to a local destination for further processing.
class statistics::rsync_job::webrequest {

    # Make sure destination directories exist.
    # Too bad I can't do this with recurse => true.
    # See: https://projects.puppetlabs.com/issues/86
    # for a much too long discussion on why I can't.
    file { [
        '/a/squid',
        '/a/squid/archive',
        '/a/aft',
        '/a/aft/archive',
        '/a/public-datasets',
    ]:
        ensure  => directory,
        owner   => 'stats',
        group   => 'wikidev',
        mode    => '0775',
    }

    # wikipedia zero logs from oxygen
    statistics::rsync_job { 'wikipedia_zero':
        source      => 'oxygen.wikimedia.org::udp2log/webrequest/archive/zero*.gz',
        destination => '/a/squid/archive/zero',
    }

    # API logs from erbium
    statistics::rsync_job { 'api':
        source      => 'erbium.eqiad.wmnet::udp2log/webrequest/archive/api-usage*.gz',
        destination => '/a/squid/archive/api',
    }

    # sampled-1000 logs from erbium
    statistics::rsync_job { 'sampled_1000':
        source      => 'erbium.eqiad.wmnet::udp2log/webrequest/archive/sampled-1000*.gz',
        destination => '/a/squid/archive/sampled',
    }

    # edit logs from oxygen
    statistics::rsync_job { 'edits':
        source      => 'oxygen.wikimedia.org::udp2log/webrequest/archive/edits*.gz',
        destination => '/a/squid/archive/edits',
    }

    # mobile logs from oxygen
    statistics::rsync_job { 'mobile':
        source      => 'oxygen.wikimedia.org::udp2log/webrequest/archive/mobile*.gz',
        destination => '/a/squid/archive/mobile',
    }
}

