# logging (udp2log) servers

# base node definition from which logging nodes (emery, oxygen, etc)
# inherit. Note that there is no real node named "base_analytics_logging_node".
# This is done as a base node primarily so that we can override the
# $nagios_contact_group variable.
node "base_analytics_logging_node" {

    # include analytics in nagios_contact_group.
    # This is used by class base::monitoring::host for
    # notifications when a host or important service goes down.
    # NOTE:  This cannot be a fully qualified var
    # (i.e. $base::nagios_contact_group) because puppet does not
    # allow setting variables in other namespaces.  I could
    # parameterize class base AND class stanrdard and pass
    # the var down the chain, but that seems like too much
    # modification for just this.  Instead this overrides
    # the default contact_group of 'admins' set in class base.
    $nagios_contact_group = "admins,analytics"

    include
        standard,
        role::logging
}

class role::logging
{
    system::role { "role::logging": description => "log collector" }

    # default gid
    $gid=500

    include
        groups::wikidev,
        admins::restricted,
        nrpe,
        geoip
}

# mediawiki udp2log instance.  Does not use monitoring.
class role::logging::mediawiki($monitor = true, $log_directory = '/home/wikipedia/logs' ) {
    system::role { "role::logging:mediawiki": description => "MediaWiki log collector" }

    class { "misc::udp2log": monitor => $monitor }
    include misc::udp2log::utilities,
        misc::udp2log::iptables

    $error_processor_host = $::realm ? {
        production => 'vanadium.eqiad.wmnet',
        labs       => "deployment-fluoride.${::site}.wmflabs",
    }

    # TODO remove once beta cluster is migrated to eqiad
    $logtash_host_beta = $::site ? {
        eqiad => 'deployment-logstash1.eqiad.wmflabs',
        pmtpa => 'logstash.pmtpa.wmflabs',
    }
    $logstash_host = $::realm ? {
        # TODO: Find a way to use multicast that doesn't cause duplicate
        # messages to be stored in logstash. This is a SPOF.
        production => 'logstash1001.eqiad.wmnet',
        labs       => $logtash_host_beta,
    }

    $logstash_port = 8324

    misc::udp2log::instance { "mw":
        log_directory    =>    $log_directory,
        monitor_log_age    =>    false,
        monitor_processes    =>    false,
        monitor_packet_loss    =>    false,
        template_variables => {
            error_processor_host => $error_processor_host,
            error_processor_port => 8423,

            # forwarding to logstash
            logstash_host => $logstash_host,
            logstash_port => $logstash_port,
        },
    }

    cron { "mw-log-cleanup":
        command => "/usr/local/bin/mw-log-cleanup",
        user => root,
        hour => 2,
        minute => 0
    }

    file { "/usr/local/bin/mw-log-cleanup":
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => "puppet:///files/misc/scripts/mw-log-cleanup",
    }

    file { '/usr/local/bin/exceptionmonitor':
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        content => template('misc/exceptionmonitor.erb'),
    }
}

class role::beta::logging::mediawiki {

    class { 'role::logging::mediawiki':
        log_directory => '/data/project/logs';
    }

}

# == Class role::logging::mediawiki::errors
# fluorine's udp2log instance forwards MediaWiki exceptions and fatals
# to vanadium, as configured in templates/udp2log/filters.mw.erb. This
# role provisions a metric module that reports error counts to Ganglia.
# Configures a Ganglia metric module that listens on a UDP port for
# MediaWiki fatal and exception log messages and reports them to Ganglia.
#
class role::logging::mediawiki::errors {
    system::role { 'role::logging::mediawiki::errors':
        description => 'Report MediaWiki exceptions and fatals to Ganglia',
    }

    class { 'mediawiki::monitor::errors':
        port => 8423,
    }
}

# == Class role::logging::relay::webrequest-multicast
# Sets up a multicast relay using socat for
# webrequest log streams (squid, varnish, nginx etc.).
# Anything sent to this node on port 8419 will be
# relayed to the 233.58.59.1:8420 multicast group.
#
class role::logging::relay::webrequest-multicast {
    system::role { 'role::logging::relay::webrequest-multicast':
        description => 'Webrequest log stream unicast to multicast relay',
    }

    misc::logging::relay { 'webrequest':
        listen_port      => '8419',
        destination_ip   => '233.58.59.1',
        destination_port => '8420',
        multicast        => true,
    }
}

# == Class role::logging::relay::eventlogging
# Relays EventLogging traffic over to Vandadium.
#
class role::logging::relay::eventlogging {
    system::role { 'misc::logging::relay::eventlogging':
        description => 'esams bits event logging to vanadium relay',
    }

    misc::logging::relay { 'eventlogging':
        listen_port      => '8422',
        destination_ip   => '10.64.21.123',
        destination_port => '8422',
    }
}


# udp2log base role class
class role::logging::udp2log {
    include misc::udp2log,
        misc::udp2log::utilities

    $log_directory               = '/a/log'

    file { $log_directory:
        ensure => 'directory',
    }

    # Set up an rsync daemon module for udp2log logrotated
    # archives.  This allows stat1 to copy logs from the
    # logrotated archive directory
    class { 'misc::udp2log::rsyncd':
        path    => $log_directory,
        require => File[$log_directory],
    }
}

# nginx machines are configured to log to port 8421.
class role::logging::udp2log::nginx inherits role::logging::udp2log {
    $nginx_log_directory = "$log_directory/nginx"

    misc::udp2log::instance { 'nginx':
        port                => '8421',
        log_directory       => $nginx_log_directory,
        # don't monitor packet loss,
        # we aren't keeping packet loss log, 
        # and nginx sequence numbers are messed up anyway.
        monitor_packet_loss => false
    }
}

class role::logging::webstatscollector {
    # datasets account is needed so that snapshot1
    # can rsync webstats dumps to dataset2 (dumps.wikimedia.org).
    include accounts::datasets

    # webstatscollector package creates this directory.
    # webstats-collector process writes dump files here.
    $webstats_dumps_directory = '/a/webstats/dumps'

    package { 'webstatscollector': ensure => installed }
    service { 'webstats-collector':
        ensure     => running,
        hasstatus  => false,
        hasrestart => true,
        require    => Package['webstatscollector'],
    }
    # install a nrpe check for the webstatscollector collector process
    nrpe::monitor_service { 'webstats-collector':
        description   => "webstats-collector process running",
        nrpe_command  => '/usr/lib/nagios/plugins/check_procs --argument-array /usr/local/bin/collector -c 1:2',
        contact_group => 'analytics',
        retries       => 10,
        require       => Service['webstats-collector']
    }

    # Gzip pagecounts files hourly.
    cron { 'webstats-dumps-gzip':
        command => "/bin/gzip ${webstats_dumps_directory}/pagecounts-????????-?????? 2> /dev/null",
        minute  => 2,
        user    => 'nobody',
        require => Service['webstats-collector'],
    }

    # Delete webstats dumps that are older than 10 days daily.
    cron { 'webstats-dumps-delete':
        command => "/usr/bin/find ${webstats_dumps_directory} -maxdepth 1 -type f -mtime +10 -delete",
        minute  => 28,
        hour    => 1,
        user    => 'nobody',
        require => Service['webstats-collector'],
    }
}


# emery is a generic webrequests udp2log host.
class role::logging::udp2log::emery inherits role::logging::udp2log {
    # udp2log::instance will ensure this is created
    $webrequest_log_directory    = "$log_directory/webrequest"

    misc::udp2log::instance { 'emery': 
        log_directory => $webrequest_log_directory,
    }
}

# oxygen is a generic webrequests udp2log host
# mostly running wikipedia zero filters.
class role::logging::udp2log::oxygen inherits role::logging::udp2log {
    # include this to infer mobile varnish frontend hosts in
    # udp2log filter template.
    include role::cache::configuration

    # udp2log::instance will ensure this is created
    $webrequest_log_directory    = "$log_directory/webrequest"

    # install custom filters here
    $webrequest_filter_directory = "$webrequest_log_directory/bin"
    file { $webrequest_filter_directory:
        ensure => directory,
        mode   => 0755,
        owner  => 'udp2log',
        group  => 'udp2log',
    }

    file { "$webrequest_filter_directory/vu.awk":
        ensure => 'file',
        source => 'puppet:///files/udp2log/vu.awk',
        mode   => 0755,
        owner  => 'udp2log',
        group  => 'udp2log',
    }
    file { "$webrequest_filter_directory/minnesota.awk":
        ensure => 'file',
        source => 'puppet:///files/udp2log/minnesota.awk',
        mode   => 0755,
        owner  => 'udp2log',
        group  => 'udp2log',
    }

    misc::udp2log::instance { 'oxygen':
        multicast       => true,
        packet_loss_log => '/var/log/udp2log/packet-loss.log',
        log_directory   => $webrequest_log_directory,
        template_variables => { 'webrequest_filter_directory' => $webrequest_filter_directory },
    }
}

# lucene udp2log instance for capturing search logs
class role::logging::udp2log::lucene inherits role::logging::udp2log {
    # udp2log::instance will ensure this is created
    $lucene_log_directory    = "$log_directory/lucene"

    misc::udp2log::instance { 'lucene': 
        port                 => '51234',
        log_directory        => $lucene_log_directory,
        monitor_packet_loss  => false,
    }
}
# == Class role::logging::udp2log::erbium
# Erbium udp2log instance:
# - Fundraising: This requires write permissions on the netapp mount.
# - Webstatscollector 'filter'
#
class role::logging::udp2log::erbium inherits role::logging::udp2log {
    include misc::fundraising::udp2log_rotation,
        accounts::file_mover

    # udp2log::instance will ensure this is created
    $webrequest_log_directory    = "$log_directory/webrequest"

    # keep fundraising logs in a subdir
    $fundraising_log_directory = "${log_directory}/fundraising"

    file { "${fundraising_log_directory}":
        ensure  => 'directory',
        mode    => '0775',
        owner   => 'udp2log',
        group   => 'file_mover',
        require => Class['accounts::file_mover'],
    }
    file { "${fundraising_log_directory}/logs":
        ensure  => 'directory',
        mode    => '2775',  # make sure setgid bit is set.
        owner   => 'udp2log',
        group   => 'file_mover',
        require => Class['accounts::file_mover'],
    }

    # erbium run webstatscollector's filter process,
    # sending filtered logs to gadolinium's collector process.
    package { 'webstatscollector':
        ensure => 'installed',
    }

    misc::udp2log::instance { 'erbium':
        multicast          => true,
        packet_loss_log    => '/var/log/udp2log/packet-loss.log',
        log_directory      => $webrequest_log_directory,
        template_variables => {
            'fundraising_log_directory' => $fundraising_log_directory
        },
        require            => [
            File["${fundraising_log_directory}/logs"],
            Package['webstatscollector']
        ],
    }


    # install a nrpe check for the webstatscollector filter process
    nrpe::monitor_service { 'webstats-filter':
        description   => "webstats-filter process running",
        nrpe_command  => '/usr/lib/nagios/plugins/check_procs --argument-array /usr/local/bin/filter -c 1:3',
        contact_group => 'analytics',
        retries       => 10,
        require       => Misc::Udp2log::Instance['erbium'],
    }
}

# misc udp2log instance, mainly for a post-udp2log era...one day :)
class role::logging::udp2log::misc {
    include misc::udp2log,
        misc::udp2log::utilities

    misc::udp2log::instance { 'misc':
        multicast          => true,
        packet_loss_log    => '/var/log/udp2log/packet-loss.log',
    }
}
