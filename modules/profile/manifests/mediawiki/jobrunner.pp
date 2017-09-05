class profile::mediawiki::jobrunner(
    $statsd = hiera('statsd'),
    $queue_servers = hiera('profile::mediawiki::jobrunner::queue_servers'),
    $aggr_servers  = hiera('profile::mediawiki::jobrunner::aggr_servers'),
    $load_factor   = hiera('profile::mediawiki::load_factor', 1.0),
    $runners = hiera('profile::mediawiki::jobrunner::runners'),
) {
    # Parameters we don't need to override
    $port = 9005
    $local_only_port = 9006

    # The jobrunner script that submits jobs to hhvm
    $active = ($::mw_primary == $::site)
    class { '::mediawiki::jobrunner':
        port          => $port,
        running       => $active,
        statsd_server => $statsd,
        queue_servers => $queue_servers,
        aggr_servers  => $aggr_servers,
        concurrency   => floor($load_factor * $facts['processorcount']),
        runners       => $runners,
    }

    # Special HHVM setup
    class { '::apache::mpm':
        mpm => 'worker',
    }

    apache::conf { 'hhvm_jobrunner_port':
        priority => 1,
        content  => inline_template("# This file is managed by Puppet\nListen <%= @port %>\nListen <%= @local_only_port %>\n"),
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
}
