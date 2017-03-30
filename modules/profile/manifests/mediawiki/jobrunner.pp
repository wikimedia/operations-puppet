class profile::mediawiki::jobrunner(
    $statsd = hiera('statsd'),
    $queue_servers = hiera('profile::mediawiki::jobrunner::queue_servers'),
    $aggr_servers  = hiera('profile::mediawiki::jobrunner::aggr_servers'),
    $runners = hiera('profile::mediawiki::jobrunner::runners'),
    $active = hiera('jobrunner_active', true),
) {
    # Parameters we don't need to override
    $port = 9005

    class { '::mediawiki::jobrunner':
        port                          => $port,
        running                       => $active,
        statsd_server                 => $statsd,
        queue_servers                 => $queue_servers,
        aggr_servers                  => $aggr_servers,
        runners_basic                 => pick($runners['basic'], 0),
        runners_html                  => pick($runners['html'], 0),
        runners_upload                => pick($runners['upload']),
        runners_gwt                   => pick($runners['gwt']),
        runners_transcode             => pick($runners['transcode'], 0),
        runners_transcode_prioritized => pick($runners['transcode_prioritized'], 0),
        runners_translate             => pick($runners['translate'], 0)
    }


    ::monitoring::service { 'jobrunner_http_hhvm':
        description   => 'HHVM jobrunner',
        check_command => 'check_http_jobrunner',
        retries       => 2,
    }

    # Monitor TCP Connection States
    ::diamond::collector { 'TcpConnStates':
        source => 'puppet:///modules/diamond/collector/tcpconnstates.py',
    }

    # Monitor Ferm/Netfilter Connection Flows
    ::diamond::collector { 'NfConntrackCount':
        source => 'puppet:///modules/diamond/collector/nf_conntrack_counter.py',
    }

    ::ferm::service { 'mediawiki-jobrunner':
        proto   => 'tcp',
        port    => $port,
        notrack => true,
        srange  => '$DOMAIN_NETWORKS',
    }

}
