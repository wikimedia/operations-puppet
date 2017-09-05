class profile::mediawiki::jobrunner(
    $statsd = hiera('statsd'),
    $queue_servers = hiera('profile::mediawiki::jobrunner::queue_servers'),
    $aggr_servers  = hiera('profile::mediawiki::jobrunner::aggr_servers'),
    $runners = hiera('profile::mediawiki::jobrunner::runners'),
) {
    # Parameters we don't need to override
    $port = 9005
    $local_only_port = 9006

    # The jobrunner script that submits jobs to hhvm
    $active = ($::mw_primary == $::site)
    class { '::mediawiki::jobrunner':
        port                          => $port,
        running                       => $active,
        statsd_server                 => $statsd,
        queue_servers                 => $queue_servers,
        aggr_servers                  => $aggr_servers,
        runners_basic                 => pick($runners['basic'], 0),
        runners_html                  => pick($runners['html'], 0),
        runners_upload                => pick($runners['upload'], 0),
        runners_gwt                   => pick($runners['gwt'], 0),
        runners_transcode             => pick($runners['transcode'], 0),
        runners_transcode_prioritized => pick($runners['transcode_prioritized'], 0),
        runners_translate             => pick($runners['translate'], 0)
    }

    # Special HHVM setup
    class { '::apache::mod::proxy_fcgi': }

    class { '::apache::mpm':
        mpm => 'worker',
    }

    apache::conf { 'hhvm_jobrunner_port':
        priority => 1,
        content  => inline_template("# This file is managed by Puppet\nListen <%= @port %>Listen <%= @local_only_port %>\n"),
    }

    apache::site{ 'hhvm_jobrunner':
        priority => 1,
        content  => template('profile/mediawiki/jobrunner/site.conf.erb'),
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

    # TODO: restrict this to monitoring and localhost only.
    ::ferm::service { 'mediawiki-jobrunner':
        proto   => 'tcp',
        port    => $port,
        notrack => true,
        srange  => '$DOMAIN_NETWORKS',
    }
}
