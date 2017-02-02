# mediawiki udp2log instance.  Does not use monitoring.
class role::logging::mediawiki::udp2log(
    $monitor = true,
    $log_directory = '/srv/mw-log',
    $rotate = 1000,
    $rsync_slow_parse = false,
    $forward_messages = false,
    $mirror_destinations = undef,
) {
    system::role { 'role::logging:mediawiki::udp2log':
        description => 'MediaWiki log collector',
    }

    include base::firewall

    # Rsync archived slow-parse logs to dumps.wikimedia.org.
    # These are available for download at http://dumps.wikimedia.org/other/slow-parse/
    include ::dataset::user
    if ($rsync_slow_parse) {
        cron { 'rsync_slow_parse':
            command     => "/usr/bin/rsync -rt ${log_directory}/archive/slow-parse.log*.gz dumps.wikimedia.org::slow-parse/",
            hour        => 23,
            minute      => 15,
            environment => 'MAILTO=ops-dumps@wikimedia.org',
            user        => 'datasets',
        }
    }

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
        mode   => '0544',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/udp2log/demux.py',
    }

    $logstash_host = $::realm ? {
        # TODO: Find a way to use multicast that doesn't cause duplicate
        # messages to be stored in logstash. This is a SPOF.
        production => 'logstash1001.eqiad.wmnet',
        labs       => 'deployment-logstash2.deployment-prep.eqiad.wmflabs',
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
            error_processor_host => 'eventlog1001.eqiad.wmnet',
            error_processor_port => 8423,

            # forwarding to logstash
            logstash_host        => $logstash_host,
            logstash_port        => $logstash_port,
        },
    }

    # Allow rsyncing of udp2log generated files to
    # analysis hosts.
    class { 'udp2log::rsyncd':
        path => $log_directory,
    }

    cron { 'mw-log-cleanup':
        command => '/usr/local/bin/mw-log-cleanup',
        user    => 'root',
        hour    => 2,
        minute  => 0
    }

    # move files to module?
    # lint:ignore:puppet_url_without_modules
    file { '/usr/local/bin/mw-log-cleanup':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/role/logging/mw-log-cleanup',
    }

    file { '/usr/local/bin/exceptionmonitor':
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        content => template('role/logging/exceptionmonitor.erb'),
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
