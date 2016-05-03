class role::mediawiki::jobrunner {
    system::role { 'role::mediawiki::jobrunner': }

    include ::role::mediawiki::common
    include ::mediawiki::jobrunner

    monitoring::service { 'jobrunner_http_hhvm':
        description   => 'HHVM jobrunner',
        check_command => 'check_http_jobrunner',
        retries       => 2,
    }

    # Monitor TCP Connection States
    diamond::collector { 'TcpConnStates':
        source => 'puppet:///modules/diamond/collector/tcpconnstates.py',
    }

    # Monitor Ferm/Netfilter Connection Flows
    diamond::collector { 'NfConntrackCount':
        source => 'puppet:///modules/diamond/collector/nf_conntrack_counter.py',
    }

    ferm::service { 'mediawiki-jobrunner':
        proto   => 'tcp',
        port    => $::mediawiki::jobrunner::port,
        notrack => true,
        srange  => '$INTERNAL',
    }
}
