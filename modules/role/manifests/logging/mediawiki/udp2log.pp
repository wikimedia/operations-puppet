# mediawiki udp2log instance.  Does not use monitoring.
#
# filtertags: labs-project-deployment-prep
class role::logging::mediawiki::udp2log(
    $logstash_host,
    $monitor = true,
    $log_directory = '/srv/mw-log',
    $rotate = 1000,
    $forward_messages = false,
    $mirror_destinations = undef,
) {
    system::role { 'logging:mediawiki::udp2log':
        description => 'MediaWiki log collector',
    }

    include ::standard
    include ::profile::base::firewall

    class { '::udp2log':
        monitor          => $monitor,
        default_instance => false,
    }

    ferm::rule { 'udp2log_accept_all_wikimedia':
        rule => 'saddr ($DOMAIN_NETWORKS) proto udp ACCEPT;',
    }

    ferm::rule { 'udp2log_notrack':
        table => 'raw',
        chain => 'PREROUTING',
        rule  => 'saddr ($DOMAIN_NETWORKS) proto udp NOTRACK;',
    }

    file { '/usr/local/bin/demux.py':
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/udp2log/demux.py',
    }

    file { '/usr/local/bin/udpmirror.py':
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/udp2log/udpmirror.py',
    }

    $logstash_port = 8324

    udp2log::instance { 'mw':
        log_directory       =>   $log_directory,
        monitor_log_age     =>   false,
        monitor_processes   =>   false,
        rotate              =>   $rotate,
        forward_messages    =>   $forward_messages,
        mirror_destinations =>   $mirror_destinations,
        template_variables  => {
            # forwarding to logstash
            logstash_host => $logstash_host,
            logstash_port => $logstash_port,
        },
    }

    # Allow rsyncing of udp2log generated files to
    # analysis hosts.
    class { 'udp2log::rsyncd':
        path        => $log_directory,
        hosts_allow => hiera('statistics_servers', 'stat1005.eqiad.wmnet')
    }

    cron { 'mw-log-cleanup':
        command => '/usr/local/bin/mw-log-cleanup',
        user    => 'root',
        hour    => 2,
        minute  => 0
    }

    file { '/usr/local/bin/mw-log-cleanup':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/role/logging/mw-log-cleanup',
    }

    file { '/etc/profile.d/mw-log.sh':
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        content => "MW_LOG_DIRECTORY=${log_directory}\n",
    }

    file { '/usr/local/bin/fatalmonitor':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/role/logging/fatalmonitor',
    }
}
