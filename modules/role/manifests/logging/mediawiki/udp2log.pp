# mediawiki udp2log instance.  Does not use monitoring.
#
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

    include ::profile::base::production
    include ::profile::base::firewall
    include ::profile::mediawiki::mwlog
    include ::profile::mediawiki::system_users
    # Include geoip databases and CLI.
    class { '::geoip': }

    class { '::udp2log':
        monitor          => $monitor,
        default_instance => false,
    }

    class { '::bsection': }

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

    # udp_tee will by default bind 0.0.0.0:8420 and relay to localhost:8421
    class { '::profile::rsyslog::udp_tee': }

    udp2log::instance { 'mw':
        port                =>   '8421',
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


    systemd::timer::job { 'mw-log-cleanup':
        ensure      => 'present',
        user        => 'root',
        description => 'cleanup mediawiki logs',
        command     => '/usr/local/bin/mw-log-cleanup',
        interval    => {'start' => 'OnCalendar', 'interval' => '*-*-* 02:00:00'},
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
        ensure => absent
    }

    file { '/usr/local/bin/logspam-watch':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/role/logging/logspam-watch.sh',
    }

    file { '/usr/local/bin/logspam':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/role/logging/logspam.pl',
    }

    # This Redis instance is used to receive PHP stack traces from
    # MediaWiki app servers, for processing by Arc Lamp on webperf#2 servers.
    # (see profile::webperf::arclamp).
    redis::instance { '6379':
        settings => {
            maxmemory                   => '1Mb',
            stop_writes_on_bgsave_error => 'no',
            bind                        => '0.0.0.0',
        },
    }

    ferm::service { 'xenon_redis':
      proto  => 'tcp',
      port   => 6379,
      srange => '$DOMAIN_NETWORKS',
    }
}
